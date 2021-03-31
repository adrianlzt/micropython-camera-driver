# micropython-camera-driver

This repository adds camera (OV2640) support to MicroPython for the ESP32 family.

I could have forked the micropython repository and include the camera driver. However, I chose to include in this repository only the files that are required, so that you can always use the last version of MicroPython and add these files to add camera support.

For more information visit this tutorial: https://lemariva.com/blog/2020/06/micropython-support-cameras-m5camera-esp32-cam-etc

## Example
```python
import camera

# ESP32-CAM (default configuration) - https://bit.ly/2Ndn8tN
camera.init(0, format=camera.JPEG)  

# M5Camera (Version B) - https://bit.ly/317Xb74
camera.init(0, d0=32, d1=35, d2=34, d3=5, d4=39, d5=18, d6=36, d7=19,
            format=camera.JPEG, framesize=camera.FRAME_VGA, xclk_freq=camera.XCLK_10MHz,
            href=26, vsync=25, reset=15, sioc=23, siod=22, xclk=27, pclk=21)   #M5CAMERA

# T-Camera Mini (green PCB) - https://bit.ly/31H1aaF
import axp202 # source https://github.com/lewisxhe/AXP202_PythonLibrary
# USB current limit must be disabled (otherwise init fails)
axp=axp202.PMU( scl=22, sda=21, address=axp202.AXP192_SLAVE_ADDRESS  )
limiting=axp.read_byte( axp202.AXP202_IPS_SET )
limiting &= 0xfc
axp.write_byte( axp202.AXP202_IPS_SET, limiting )

camera.init(0, d0=5, d1=14, d2=4, d3=15, d4=18, d5=23, d6=36, d7=39,
            format=camera.JPEG, framesize=camera.FRAME_VGA, 
            xclk_freq=camera.XCLK_20MHz,
            href=25, vsync=27, reset=-1, pwdn=-1,
            sioc=12, siod=13, xclk=32, pclk=19)

# The parameters: format=camera.JPEG, xclk_freq=camera.XCLK_10MHz are standard for all cameras.
# You can try using a faster xclk (20MHz), this also worked with the esp32-cam and m5camera
# but the image was pixelated and somehow green.

## Other settings:
# flip up side down
camera.flip(1)
# left / right
camera.mirror(1)

# framesize
camera.framesize(camera.FRAME_240x240)
# The options are the following:
# FRAME_96X96 FRAME_QQVGA FRAME_QCIF FRAME_HQVGA FRAME_240X240
# FRAME_QVGA FRAME_CIF FRAME_HVGA FRAME_VGA FRAME_SVGA
# FRAME_XGA FRAME_HD FRAME_SXGA FRAME_UXGA FRAME_FHD
# FRAME_P_HD FRAME_P_3MP FRAME_QXGA FRAME_QHD FRAME_WQXGA
# FRAME_P_FHD FRAME_QSXGA
# Check this link for more information: https://bit.ly/2YOzizz

# special effects
camera.speffect(camera.EFFECT_NONE)
# The options are the following:
# EFFECT_NONE (default) EFFECT_NEG EFFECT_BW EFFECT_RED EFFECT_GREEN EFFECT_BLUE EFFECT_RETRO

# white balance
camera.whitebalance(camera.WB_NONE)
# The options are the following:
# WB_NONE (default) WB_SUNNY WB_CLOUDY WB_OFFICE WB_HOME

# saturation
camera.saturation(0)
# -2,2 (default 0). -2 grayscale 

# brightness
camera.brightness(0)
# -2,2 (default 0). 2 brightness

# contrast
camera.contrast(0)
#-2,2 (default 0). 2 highcontrast

# quality
camera.quality(10)
# 10-63 lower number means higher quality

buf = camera.capture()

```

### Important
* Except when using CIF or lower resolution with JPEG, the driver requires PSRAM to be installed and activated. This is activated, but it is limited due that MicroPython needs RAM.
* Using YUV or RGB puts a lot of strain on the chip because writing to PSRAM is not particularly fast. The result is that image data might be missing. This is particularly true if WiFi is enabled. If you need RGB data, it is recommended that JPEG is captured and then turned into RGB using `fmt2rgb888 or fmt2bmp/frame2bmp`. The conversion is not supported. The formats are included, but I got almost every time out of memory, trying to capture an image in a different format than JPEG.

## Firmware

I've included a compiled MicroPython firmware with camera and BLE support (check the `firmware` folder). The firmware was compiled using esp-idf 4.x.

To flash it to the board, you need to type the following:
```sh
esptool.py --chip esp32 --port /dev/ttyUSB0 erase_flash
esptool.py --chip esp32 --port /dev/ttyUSB0 --baud 460800 write_flash -z 0x1000 micropython_cmake_9fef1c0bd_esp32_idf4.x_ble_camera.bin
```
More information is available in this [tutorial](https://lemariva.com/blog/2020/03/tutorial-getting-started-micropython-v20).

If you want to compile your driver from scratch follow the next section:

## DIY

- Read this section if you want to include the camera support to MicroPython from scratch. To do that follow these steps:
- if you get stuck, those pages are a good help:
  - https://github.com/micropython/micropython/tree/master/ports/esp32
  - https://docs.espressif.com/projects/esp-idf/en/stable/esp32/get-started/index.html#installation-step-by-step

- Note that up to micropython version 1.14, the build tool for the esp32 port is Make. Starting with this [PR](https://github.com/micropython/micropython/pull/6892), it is CMAKE. You can find more discussion in this [micropython forum blog post](https://forum.micropython.org/viewtopic.php?f=18&t=9820)
- The below only works with Cmake


1. Clone the MicroPython repository:
    ```
    git clone --recursive https://github.com/micropython/micropython.git
    ```
    Note: The MicroPython repo changes a lot, I've done this using the version with the hash 9fef1c0bd (release=`1.14.0-dirty`).

    :warning: If you want to directly replace the original files with the provided in this repository, be sure that you've taken the same commit hash. MicroPython changes a lot, and you'll compiling issues if you ignore this warning.

2. Copy the files of this repository inside the folder `ports/esp32`. You can create a tgz file `create_tgz.sh` for easy transfer.
   1. Did not include the `mpconfigport.h`, `main.c`, and `main/CMakeLists.txt` in here as this only makes sense for a final release of micropython and not a version in between two releases. 

3. For the files `mpconfigport.h`, `main.c`, and `main/CMakeLists.txt` make the following modifications to the original ones:
    * `mpconfigport.h`
        1. add the line
        ```
           extern const struct _mp_obj_module_t mp_module_camera;
        ```
        in the code block below `// extra built in modules to add to the list of known ones` (approx. line 184)

        1. add the line:
        ```
            { MP_OBJ_NEW_QSTR(MP_QSTR_camera), (mp_obj_t)&mp_module_camera }, \
        ```
        in the code block below `#define MICROPY_PORT_BUILTIN_MODULES \` (approx. line 194/195)

    * `main.c`: modify the lines inside the `#if CONFIG_ESP32_SPIRAM_SUPPORT || CONFIG_SPIRAM_SUPPORT`, they should look like:
        ```
            size_t mp_task_heap_size;
            mp_task_heap_size = 2 * 1024 * 1024;
            void *mp_task_heap = malloc(mp_task_heap_size);
            ESP_LOGI("main", "Allocated %dK for micropython heap at %p", mp_task_heap_size/1024, mp_task_heap);
        ```

    * `main/CMakeLists.txt`:
        1. add the lines: `esp32-camera` under the `set(IDF_COMPONENTS`  (approx. line 78)

        2. add the line: `${PROJECT_DIR}/modcamera.c` under the `set(MICROPY_SOURCE_PORT` (approx. line 34)

4. Clone the `https://github.com/lemariva/esp32-camera` repository inside the `~/esp/esp-idf/components` folder.
    ```sh
        cd ~/esp/esp-idf/components
        git clone https://github.com/espressif/esp32-camera
        # it was compiled with this commit 2dded7c
        git checkout 2dded7c
    ```

5. Compile and deploy MicroPython following the instructions from this [tutorial](https://lemariva.com/blog/2020/03/tutorial-getting-started-micropython-v20). But, use the following compiling options:
    ```sh
    # make sure the idf.py is in your path, can check it with 
    which idf.py
    # build
    make BOARD=GENERIC_CAM
    # flash
    make BOARD=GENERIC_CAM deploy 
    # or 
    idf.py -B build-GENERIC_SPIRAM flash
    ```
