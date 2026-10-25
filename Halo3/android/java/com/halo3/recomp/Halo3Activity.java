package com.halo3.recomp;

import android.content.Context;
import android.hardware.Sensor;
import android.os.Bundle;
import android.view.WindowManager;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.util.ArrayList;

import org.libsdl.app.SDLActivity;
import org.libsdl.app.SDLSurface;

/**
 * Halo 3 recomp launcher.
 *
 * Files live in the app's folder on the device's storage:
 *   Android/data/com.halo3.recomp/files/game/       <- game files (maps, bink, default.xex ...)
 *   Android/data/com.halo3.recomp/files/userdata/   <- saves
 *   Android/data/com.halo3.recomp/files/halo3.log   <- log
 *   Android/data/com.halo3.recomp/files/args.txt    <- optional extra flags, one per line
 *   Android/data/com.halo3.recomp/files/env.txt     <- optional KEY=VALUE environment lines
 */
public class Halo3Activity extends SDLActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
    }

    @Override
    protected SDLSurface createSDLSurface(Context context) {
        // SDL listens to the accelerometer all the time (for rotation and an
        // accelerometer joystick). Each sensor event woke the game's UI thread,
        // which also puts frames on screen - the game doesn't use it.
        return new SDLSurface(context) {
            @Override
            protected void enableSensor(int sensortype, boolean enabled) {
                if (sensortype == Sensor.TYPE_ACCELEROMETER) {
                    return;
                }
                super.enableSensor(sensortype, enabled);
            }
        };
    }

    @Override
    protected String[] getLibraries() {
        // librexruntime.so (with SDL inside) is loaded first so its JNI entry
        // points are registered before libmain.so (the game) starts.
        return new String[] { "c++_shared", "rexruntime", "main" };
    }

    @Override
    protected String[] getArguments() {
        File base = getExternalFilesDir(null);
        String b = base.getAbsolutePath();
        new File(b, "game").mkdirs();
        new File(b, "userdata").mkdirs();

        ArrayList<String> args = new ArrayList<>();
        args.add("--gpu_plugin=xenos");
        // Halo 3 uses texture fetch constants with an "invalid" type for some of its
        // textures (menu background, effects); accept them like the console does.
        args.add("--gpu_allow_invalid_fetch_constants=true");
        // Halo 3 renders to 8_8_8_8_GAMMA targets and expects real 8-bit storage;
        // the 16-bit emulation of them makes the menu scene far too bright.
        args.add("--gamma_render_target_as_unorm16=false");
        // Copying shader memory writes back to the CPU stalled the GPU ~10 times
        // per frame (10 -> 13.5 fps on the menu without it); Halo 3 does not need it.
        args.add("--readback_memexport=false");
        // Render without 4x MSAA: about +33% speed on the menu (13.5 -> 18 fps).
        // Known side effect: black boxes for a moment right after skipping the intro.
        args.add("--gpu_force_msaa_1x=true");
        // Only the menu's 4-strip 3D background (pitch 1160); other MSAA images (loading/Forge) need real MSAA.
        args.add("--gpu_force_msaa_1x_pitch=1160");
        // Plain multiplies in translated shaders instead of emulating the Xbox 360
        // "0 * anything = 0" rule: about +25% on the menu, no visible difference.
        args.add("--gpu_shader_fast_multiply=true");
        // Hardware texture LOD + bias instead of explicit gradients: about +5%.
        args.add("--gpu_shader_implicit_lod=true");
        // Let the driver fuse multiply-adds in pixel shaders (small gain, no visible change).
        args.add("--gpu_shader_allow_fma=true");
        // Measure screen-space draws (clears etc.) on the CPU so EDRAM ownership copies
        // only cover what they touch: 18-25 -> 24-30 fps on the menu.
        args.add("--execute_unclipped_draw_vs_on_cpu=true");
        // Draw the 4 predicated-tiling strips as one full-screen pass (heavy menu view 43 -> ~28 ms GPU).
        args.add("--gpu_collapse_predicated_tiles=true");
        // Translate shader loops/jumps into structured SPIR-V instead of a program-counter switch:
        // Adreno gave each switch-based loop pipeline ~24 MB of scratch memory (menu 4.5 GB -> 45 MB).
        args.add("--gpu_shader_structured_loops=true");
        // GPU particle updates run as compute work before each render pass instead of
        // splitting the pass (smooth frame rate during effects; confirmed 2026-10-24).
        args.add("--vulkan_memexport_compute_hoist=true");
        // Vertex fetch picks the shared-memory buffer once per element (heavy view -1.3 ms GPU).
        args.add("--gpu_shader_vfetch_one_switch=true");
        // 12 audio frames (64 ms) of buffer: no pop at map load (2026-10-24).
        args.add("--audio_maxqframes=12");
        // Start each guest frame on an even vblank grid (as on the console):
        // late frames (>40 ms) dropped from ~95 to ~7 per 300.
        args.add("--vdswap_min_vblanks=2");
        args.add("--ui_achievement_toasts=false");
        // Evenly paced frames: FIFO presentation (VK_GOOGLE_display_timing).
        args.add("--vulkan_allow_present_mode_immediate=false");
        args.add("--vulkan_allow_present_mode_mailbox=false");
        args.add("--vulkan_allow_present_mode_fifo_relaxed=false");
        // AMD CAS upscales and sharpens the 1152x640 game image to the 1080p
        // screen in one pass: ~0.6 ms of GPU per frame vs ~1.25 ms for FSR 1
        // (EASU + RCAS), and looked as sharp to the user (2026-10-24).
        args.add("--present_effect=cas");
        args.add("--game_data_root=" + b + "/game");
        args.add("--user_data_root=" + b + "/userdata");
        args.add("--log_file=" + b + "/halo3.log");

        // Developer switch: a file named profile_on turns on the sampling profiler.
        if (new File(b, "profile_on").exists()) {
            try {
                android.system.Os.setenv("UAW_PROFILE", "1", true);
            } catch (Exception e) {
                // Ignore; profiling just stays off.
            }
        }

        // Developer switch: env.txt lines KEY=VALUE become environment variables.
        File envFile = new File(b, "env.txt");
        if (envFile.exists()) {
            try (BufferedReader r = new BufferedReader(new FileReader(envFile))) {
                String line;
                while ((line = r.readLine()) != null) {
                    line = line.trim();
                    int eq = line.indexOf('=');
                    if (eq > 0 && !line.startsWith("#")) {
                        android.system.Os.setenv(line.substring(0, eq).trim(), line.substring(eq + 1).trim(), true);
                    }
                }
            } catch (Exception e) {
                // Ignore a bad env file.
            }
        }

        File extra = new File(b, "args.txt");
        if (extra.exists()) {
            try (BufferedReader r = new BufferedReader(new FileReader(extra))) {
                String line;
                while ((line = r.readLine()) != null) {
                    line = line.trim();
                    if (!line.isEmpty() && !line.startsWith("#")) {
                        // A test setting replaces a default with the same name
                        // (a repeated option stops the game's argument parser).
                        final String opt = line;
                        final int eq = opt.indexOf('=');
                        final String key = eq > 0 ? opt.substring(0, eq + 1) : opt;
                        args.removeIf(a -> a.equals(opt) || a.startsWith(key));
                        args.add(opt);
                    }
                }
            } catch (Exception e) {
                // Ignore a bad args file; defaults still apply.
            }
        }
        return args.toArray(new String[0]);
    }
}
