# SKILL: Android Custom ROM Logging & Debugging

This skill provides comprehensive guidance on robust logging and debugging within an Android custom ROM environment, specifically targeting LineageOS/AOSP from source. It covers build configurations, kernel-level logging, system-level logging, log extraction, persistent logging, analysis tools, and thermal management debugging.

## Prerequisites

*   **ADB (Android Debug Bridge) and Fastboot**: Essential tools for interacting with Android devices.
*   **AOSP/LineageOS Build Environment**: Knowledge of setting up and building a custom ROM.
*   **Basic Linux Command-Line Proficiency**: Familiarity with `grep`, `cat`, `awk`, `sed`, etc.
*   **Rooted Device / Userdebug/Eng Build**: Many advanced debugging techniques require root access.

## 1. Build Configuration for Debugging

The build type significantly impacts log verbosity, available debugging tools, and system performance. For robust debugging, `userdebug` or `eng` builds are essential.

### Build Types Explained

*   **`user`**:
    *   **Intended for**: End-users.
    *   **Logging**: Lowest verbosity. Debugging features are mostly disabled for security and performance.
    *   **Security**: Most secure.
    *   **Performance**: Best performance, as debugging overhead is removed.
    *   **Root Access**: Not rooted.
*   **`userdebug`**:
    *   **Intended for**: Testers and developers testing the user experience with debugging capabilities.
    *   **Logging**: Moderate to high verbosity. Enables significant logging over `user` builds.
    *   **Security**: Less secure than `user`, but more secure than `eng`.
    *   **Performance**: Minimal performance impact compared to `user`, less overhead than `eng`.
    *   **Root Access**: Rooted, allowing `adb root` and advanced debugging.
*   **`eng` (Engineering)**:
    *   **Intended for**: Developers working on the platform itself.
    *   **Logging**: Highest verbosity. All debugging features are enabled.
    *   **Security**: Least secure, not suitable for production or daily use.
    *   **Performance**: Has performance overhead due to extensive debugging features and logging.
    *   **Root Access**: Rooted by default, with many development tools enabled.

### Configuring Your Build

To configure your LineageOS/AOSP build for debugging, select the appropriate build target using the `lunch` command during your build setup:

```bash
source build/envsetup.sh
lunch <product_name>-userdebug  # For userdebug build
# OR
lunch <product_name>-eng        # For engineering build
```

Replace `<product_name>` with your device's product name (e.g., `aosp_angler`, `lineage_device`). The selected build type (`userdebug` or `eng`) will automatically enable necessary debug flags and increase log verbosity during the compilation process.

## 2. Kernel-Level Logging

Kernel logs are crucial for diagnosing low-level issues like kernel panics, driver problems, or unexpected reboots.

### `dmesg`

`dmesg` (display message) shows the kernel ring buffer messages. This buffer holds messages from the kernel during boot and runtime.

*   **Access**:
    ```bash
    adb root
    adb shell dmesg
    ```
    *Note: `adb root` is typically required on `userdebug` and `eng` builds.*
*   **Filtering**: Pipe `dmesg` output to `grep` for specific keywords (e.g., `error`, `fail`, `oops`, `panic`).
*   **Usage**: Diagnose kernel crashes, driver loading issues, hardware initialization problems.

### `kmsg`

`/dev/kmsg` is a character device that provides access to the kernel ring buffer in a stream-like fashion. `dmesg` reads from this.

*   **Access**:
    ```bash
    adb root
    adb shell cat /dev/kmsg
    ```
*   **Persistent Logging**: To capture `kmsg` during boot or across reboots, you can redirect its output to a file:
    ```bash
    adb root
    adb shell "cat /dev/kmsg > /sdcard/kmsg_log.txt &" # Runs in background
    # ... after issue occurs ...
    adb pull /sdcard/kmsg_log.txt
    ```

### Kernel Debug Options (`printk` levels, `CONFIG_DYNAMIC_DEBUG`)

To enable more detailed kernel output:

*   **`printk` Levels**:
    *   The kernel uses log levels (0-7: `KERN_EMERG`, `KERN_ALERT`, `KERN_CRIT`, `KERN_ERR`, `KERN_WARNING`, `KERN_NOTICE`, `KERN_INFO`, `KERN_DEBUG`).
    *   You can set the console log level at runtime (requires root):
        ```bash
        adb shell "echo 8 > /proc/sys/kernel/printk" # Set to KERN_DEBUG (most verbose)
        ```
    *   For persistent changes, this often requires modifying kernel boot parameters or an `init.rc` script.
*   **`CONFIG_DYNAMIC_DEBUG`**:
    *   Enabling `CONFIG_DYNAMIC_DEBUG=y` in your kernel configuration (e.g., `kernel/configs/common-*-defconfig`) allows you to enable/disable debug messages for specific kernel modules, files, or functions at runtime *without recompiling the kernel*.
    *   **Enabling at runtime**: Requires `debugfs` to be mounted (usually at `/sys/kernel/debug`).
        ```bash
        adb root
        # Enable all debug messages for a specific file (e.g., driver.c)
        adb shell "echo 'file driver.c +p' > /sys/kernel/debug/dynamic_debug/control"
        # Enable all debug messages for a specific module
        adb shell "echo 'module <modulename> +p' > /sys/kernel/debug/dynamic_debug/control"
        # Enable all dynamic debug messages globally (can be very noisy!)
        adb shell "echo '=p' > /sys/kernel/debug/dynamic_debug/control"
        ```
    *   **Benefit**: Reduces performance impact compared to permanently compiling verbose `printk` statements, as messages are only processed when explicitly enabled.

### Common Kernel Issues

*   **Kernel Panics**: Indicated by messages like "Kernel panic - not syncing", "Oops:", "BUG:", followed by a stack trace in `dmesg` or `ramoops`.
    *   **Identification**: Look for `dmesg` output similar to the LineageOS example showing a `NULL pointer dereference`.
    *   **Tools**: `addr2line` and `decode_stacktrace.sh` are essential for symbolizing these stack traces.
*   **Watchdog Events**: Occur when the kernel detects a system hang or unresponsiveness, leading to a forced reboot.
    *   **Identification**: Look for "watchdog: watchdog0: watchdog did not stop!", "hung task", "soft lockup", "hard lockup" in kernel logs (`dmesg`, `ramoops`).
    *   These messages indicate that a critical kernel process failed to "pet" the watchdog timer within its allotted time.

## 3. System-Level Logging

System-level logs provide insights into the Android framework, applications, and services.

### `logcat`

`logcat` is the primary tool for viewing system and application logs.

*   **Basic Usage**:
    ```bash
    adb logcat
    ```
*   **Filtering**:
    *   **By Tag and Level**: `adb logcat <TAG>:<LEVEL> [TAG:LEVEL...] *:S`
        *   Levels: `V` (Verbose), `D` (Debug), `I` (Info), `W` (Warning), `E` (Error), `F` (Fatal), `S` (Silent - suppresses all previous).
        *   Example: `adb logcat PackageManager:I ActivityManager:W *:S` (Info for `PackageManager`, Warning for `ActivityManager`, suppress everything else).
    *   **By PID**: `adb logcat --pid=<PID>`
        *   Get PID: `adb shell pidof -s <package_name>`
        *   Example: `adb logcat --pid=$(adb shell pidof -s com.android.settings)`
    *   **By Buffer**: Use `-b` option to specify log buffer.
        *   `radio`: Telephony/radio-related messages.
        *   `events`: Interpreted binary system event messages.
        *   `main`: Default buffer (apps and some system services).
        *   `system`: System daemon and service messages.
        *   `crash`: Crashes (app, native, kernel).
        *   `all`: All buffers.
        *   `default`: `main`, `system`, `crash`.
        *   Example: `adb logcat -b crash`
*   **Buffer Management**:
    *   **Clear Buffer**: `adb logcat -c`
    *   **Set Buffer Size**: `adb logcat -G <size>` (e.g., `adb logcat -G 16M` for 16MB).
*   **Output Formatting**: Use `-v` option for verbose output.
    *   `brief` (default)
    *   `long`
    *   `process`
    *   `time` (Recommended: shows date, time, PID, tag, level)
    *   `threadtime` (Like `time`, but also includes thread ID)
    *   `raw`
    *   Example: `adb logcat -v time`

### `dumpsys`

`dumpsys` provides diagnostic information about all system services.

*   **List all services**: `adb shell dumpsys`
*   **Dump specific service**: `adb shell dumpsys <service_name>`
*   **Useful services for debugging**:
    *   `activity`: ActivityManager (ANR information, running processes, recent tasks)
    *   `battery`: Battery service state
    *   `meminfo <package_name>`: Memory usage for a specific application
    *   `wifi`: Wi-Fi service state
    *   `power`: Power manager state
    *   `cpuinfo`: CPU usage statistics
    *   `SurfaceFlinger`: Graphics and display information
    *   `thermalservice`: Thermal management status (covered in Section 7)

### `bugreport`

`bugreport` generates a comprehensive snapshot of the device's current state, including all logs, `dumpsys` outputs, and various system information.

*   **Usage**:
    ```bash
    adb bugreport bugreport.zip # Saves output to a zip file
    ```
*   **Content**: The `bugreport.zip` contains `logcat` logs (all buffers), `dmesg`, `dumpsys` outputs for all services, process lists, CPU usage, memory info, and much more.

### Identifying ANRs (Application Not Responding) and Native Crashes

*   **ANRs**:
    *   **Logcat Pattern**: Look for `E/ActivityManager: ANR in <package_name> (PID: <PID>)` followed by "Reason: Input dispatching timed out" or similar messages indicating UI thread blockage. A stack trace of the main thread will follow.
    *   **Dumpsys**: `adb shell dumpsys activity` provides details on ANRs, including the stack traces of relevant threads.
*   **Native Crashes**:
    *   **Tombstones**: When a native process crashes, a "tombstone" file is written to `/data/tombstones/`. These files contain a detailed stack trace of the crash.
        *   Pull: `adb pull /data/tombstones/`
    *   **Logcat**: Native crashes will often appear in the `crash` buffer of `logcat`, typically showing `FATAL EXCEPTION` for managed code or `signal 11 (SIGSEGV)` for native segfaults.
    *   **Tooling**: Use the `stack` script (`~/android/lineage/development/scripts/stack`) to symbolize tombstones for human-readable output (file and line numbers).

## 4. Log Extraction and Export Methods

Choosing the right method depends on the nature of the debugging task.

### Command-Line Methods

*   **`adb logcat > log.txt`**:
    *   **Pros**: Simple, real-time logging, easily filtered. Good for live debugging and short sessions.
    *   **Cons**: Stops logging if ADB connection is lost. Doesn't capture kernel or early boot logs.
    *   **Usage**: `adb logcat -v threadtime > my_app_log.txt`
*   **`adb shell logcat -f /sdcard/logcat.txt`**:
    *   **Pros**: Logs directly to a file on the device, more robust against ADB connection drops. Can be run in the background.
    *   **Cons**: Requires manual `adb pull` to retrieve. Doesn't automatically rotate logs unless configured.
    *   **Usage**:
        ```bash
        adb shell "logcat -f /sdcard/persistent_log.txt -r 1024 -n 5 &" # Rotate 5 files of 1MB
        # ...
        adb pull /sdcard/persistent_log.txt
        ```
*   **`adb bugreport`**:
    *   **Pros**: Most comprehensive single output, captures nearly all system and app state, perfect for post-mortem analysis of complex issues.
    *   **Cons**: Generates large files, takes time to execute, contains sensitive data. Not suitable for real-time monitoring.
    *   **Usage**: `adb bugreport bugreport_$(date +%Y%m%d_%H%M%S).zip`
*   **`adb pull /data/tombstones/`**:
    *   **Pros**: Directly retrieves native crash dumps.
    *   **Cons**: Only for native crashes.
*   **`adb shell dmesg > dmesg.txt`**:
    *   **Pros**: Captures kernel ring buffer.
    *   **Cons**: Snapshot in time, limited buffer size.

### APKs/Apps for Log Collection/Export

*   While general "log viewer" or "log collector" apps exist (e.g., CatLog, Logcat Reader), they are generally **not recommended** for serious ROM development.
*   **Pros**: User-friendly GUI, easy sharing for non-technical users.
*   **Cons**:
    *   Often lack root access for full log access (e.g., `radio` buffer, kernel logs).
    *   May not provide the granular control or filtering capabilities of `adb logcat`.
    *   Less robust for capturing logs during critical system failures or early boot.
    *   Adds another layer of abstraction, which can obscure issues.

### Recommendation: Best Way

The "best way" depends on the problem:

*   **For quick, live debugging of an active issue**: Use `adb logcat` with precise filtering.
*   **For comprehensive post-mortem analysis (e.g., after a crash or unexplained reboot)**: `adb bugreport` is indispensable. Supplement with `adb pull /data/tombstones/` for native crashes.
*   **For persistent logging during boot loops or hard-to-reproduce issues**: Set up persistent `logcat` to file (via `init.rc`) and rely on `ramoops`/`last_kmsg` for kernel insight.

**Developer Workflow**: Typically involves live `adb logcat` monitoring, and if an issue recurs or crashes the device, generating an `adb bugreport` and pulling any `tombstones` or `last_kmsg` files for deeper analysis.

## 5. Persistent Logging

Ensuring logs survive device reboots is critical for debugging boot loops, unexpected shutdowns, or intermittent issues.

*   **Kernel Logs (`ramoops` and `last_kmsg`)**:
    *   **`ramoops`**: A Linux kernel feature that writes the contents of the kernel log buffer to a reserved region of RAM (which survives warm reboots) before a crash. This data is then exposed via `pstore`.
        *   **Configuration**: Requires enabling `CONFIG_PSTORE=y`, `CONFIG_PSTORE_CONSOLE=y`, `CONFIG_PSTORE_RAM=y` in your kernel config and configuring a `ramoops` memory region in the device tree source (DTS).
        *   **Access**:
            *   `adb root && adb shell ls /sys/fs/pstore/` (look for `console-ramoops`, `dmesg-ramoops`, etc.)
            *   `adb logcat -b all -L` (will include `ramoops-pmsg` data if configured).
        *   **Recommendation**: Consider disabling `CONFIG_PSTORE_COMPRESS` for easier reading of raw logs.
    *   **`last_kmsg`**: Often a symlink or file in `/proc/` that contains the kernel messages from the *previous* boot. This relies on `ramoops` or a similar mechanism.
        *   **Configuration**: Enabled by kernel configs `CONFIG_ANDROID_RAM_CONSOLE=y` and `CONFIG_ANDROID_RAM_CONSOLE_ENABLE_VERBOSE=y`.
        *   **Access**: `adb root && adb shell cat /proc/last_kmsg`
*   **Persistent `logcat` to File**:
    *   Android's default `logcat` buffers are volatile. To make them persistent, you need to redirect them to a file on storage (e.g., `/data` partition).
    *   **Method**: Modify `init.rc` or add a custom `init` service to start `logcat` at boot and redirect its output to a file with rotation.
    *   **Example (`init.rc` snippet - conceptual)**:
        ```
        service persistent_logcat /system/bin/logcat -f /data/media/0/logcat.txt -r 1024 -n 10 -v time
            user root
            group log readproc
            # Set desired capabilities if needed
            # seclabel u:r:logd:s0
            disabled
            oneshot
            # If you want it to run always, remove 'oneshot' and ensure it handles restarts
            # and is properly daemonized. For simple boot-log capturing, 'oneshot' might be okay.

        on property:sys.boot_completed=1
            start persistent_logcat
        ```
    *   **Retrieval**: `adb pull /data/media/0/logcat.txt` (or `/sdcard/logcat.txt`).
    *   **Caution**: Continuous logging to internal storage can impact performance and wear. Implement log rotation (`-r <kbytes> -n <count>`) to manage file size.

## 6. Tools and Techniques for Analysis

Effective analysis of log data is key to identifying root causes.

### Tools

*   **Command-Line Utilities**:
    *   `adb`: The universal Android debugger.
    *   `grep`: Indispensable for searching for patterns, keywords, PIDs, TIDs, or specific log levels in large log files.
        *   Example: `grep "FATAL EXCEPTION" logcat.txt`
        *   Example: `grep -E "ANR|DEADLOCK" bugreport.txt`
    *   `awk`, `sed`: For advanced text processing, parsing, and reformatting log entries.
    *   `less`, `tail -f`: For viewing large files and following live log streams.
    *   `head`, `tail`: For looking at the beginning or end of log files.
    *   `diff`, `meld`: For comparing logs from working vs. broken scenarios.
*   **Logcat Colorizers**: Tools/scripts that add color to `adb logcat` output for improved readability.
    *   Many custom scripts exist online; some common ones use `awk` or Python.
    *   Example (concept for `awk`-based colorizer):
        ```bash
        adb logcat | awk '{
            if ($3 == "E") { print "\033[31m" $0 "\033[39m" } # Red for Error
            else if ($3 == "W") { print "\033[33m" $0 "\033[39m" } # Yellow for Warning
            else { print $0 }
        }'
        ```
*   **Text Editors/IDEs**: For viewing and searching large log files.
    *   `VS Code`, `Sublime Text`, `Notepad++`: Offer powerful search (regex), syntax highlighting, and large file handling.
*   **Symbolication Tools**:
    *   `stack` (AOSP script): For symbolizing native crash tombstones.
    *   `addr2line` (GNU Binutils): For translating addresses in kernel panics to file/line numbers.

### Methodologies

*   **Time Correlation**: Always cross-reference logs with timestamps. A crash in `logcat` might be preceded by a relevant kernel message in `dmesg`.
*   **Isolate and Filter**: Use `logcat` filtering (`-b`, tag:level, PID) and `grep` to narrow down the log noise to the most relevant messages.
*   **Reproduce and Observe**: Try to reliably reproduce the issue while capturing logs. This often provides the most direct insights.
*   **Baseline Comparison**: Collect logs from a known-good device/state and compare them to logs from the problematic scenario. Look for new errors, warnings, or missing expected messages.
*   **Top-Down/Bottom-Up Approach**:
    *   **Top-Down**: Start with high-level symptoms (e.g., app crash in `logcat`) and drill down to system (`dumpsys`) or kernel (`dmesg`) layers.
    *   **Bottom-Up**: Start with low-level errors (e.g., kernel panic) and see how they manifest in higher-level system/app logs.
*   **Pattern Recognition**: Look for recurring errors, sequences of events, or specific keywords that might indicate a known issue.

## 7. Thermal Management Debugging

Thermal issues (overheating, throttling) can severely impact device performance and stability.

### Log Indicators

*   **`logcat`**:
    *   Look for logs from `thermal-engine`, `ThermalService`, `PowerManagerService`.
    *   Tags: `ThermalHAL`, `ThermalDaemon`, `thermal_logger`, `ThermalEngine`.
    *   Keywords: `throttling`, `overheat`, `cooling_level`, `temperature`, `thermal zone`, `power_limit`.
*   **`dmesg`**: May show kernel-level thermal events, sensor readings, or throttling actions taken by the kernel's thermal governors.

### Kernel Parameters and SysFS

The Linux kernel's thermal framework exposes information via `sysfs`.

*   **Thermal Zones**: `/sys/class/thermal/thermal_zone<N>/`
    *   `type`: Type of thermal sensor (e.g., `cpu-thermal`, `gpu-thermal`, `battery`, `skin`).
    *   `temp`: Current temperature (typically in millicelsius).
    *   `trip_point_<N>_temp`: Configured temperature thresholds for different actions.
    *   `trip_point_<N>_type`: Type of action (e.g., `passive`, `active`, `hot`, `critical`).
*   **Cooling Devices**: `/sys/class/thermal/cooling_device<N>/`
    *   `type`: Type of cooling device (e.g., `cpu_freq_limit`, `gpu_freq_limit`, `display_brightness`).
    *   `cur_state`: Current cooling state (e.g., CPU frequency step, screen brightness reduction level).
*   **Relevant Kernel Configs**: `CONFIG_THERMAL=y`, `CONFIG_THERMAL_GOV_*` (various governors).

### System Services

*   **`dumpsys thermalservice`**: Provides a detailed summary of the Android Thermal Service's view of thermal zones, cooling devices, and current thermal status. This is one of the most direct ways to get a comprehensive thermal snapshot.
    ```bash
    adb shell dumpsys thermalservice
    ```
*   **`dumpsys power`**: Can show power-related states and potential thermal-induced limitations.

### Methods to Collect Thermal Data

*   **Continuous Monitoring**:
    ```bash
    adb shell "while true; do cat /sys/class/thermal/thermal_zone*/temp; sleep 1; done"
    ```
    (You'll need to identify the relevant `thermal_zone` indices first).
*   **Logcat During Stress Test**: Run a demanding application or benchmark while capturing `logcat` output, filtering for thermal-related tags.
*   **Bugreport**: An `adb bugreport` will include the output of `dumpsys thermalservice` and all relevant `logcat`/`dmesg` entries, providing a comprehensive view of the thermal state at the time of generation.

## Conclusion

Effective logging and debugging are cornerstones of custom ROM development. By leveraging appropriate build configurations, understanding kernel and system-level logging mechanisms, and employing robust extraction and analysis tools, developers can efficiently diagnose and resolve complex issues within the Android environment. This `SKILL.md` serves as a roadmap to empower developers with the techniques needed for successful ROM debugging and optimization.
