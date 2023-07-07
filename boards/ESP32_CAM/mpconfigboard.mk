
SDKCONFIG += boards/sdkconfig.base
SDKCONFIG += boards/sdkconfig.240mhz
SDKCONFIG += boards/ESP32_CAM/sdkconfig.esp32cam

FROZEN_MANIFEST ?= ESP32_CAM/manifest.py

PART_SRC = ESP32_CAM/partitions.csv
