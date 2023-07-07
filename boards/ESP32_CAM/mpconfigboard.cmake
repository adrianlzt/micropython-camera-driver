set(SDKCONFIG_DEFAULTS
    boards/sdkconfig.base
    boards/ESP32_CAM/sdkconfig.esp32cam
)

if(NOT MICROPY_FROZEN_MANIFEST)
    set(MICROPY_FROZEN_MANIFEST ${MICROPY_BOARD_DIR}/manifest.py)
endif()
