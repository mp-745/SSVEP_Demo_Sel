import numpy as np
from pylsl import StreamInfo, StreamOutlet
import time
import ctypes

# Load Unicorn DLL
unicorn = ctypes.cdll.LoadLibrary(
    r"C:\Users\Dhruv\OneDrive\Desktop\UCL\BCI hackathon Jan 2026\Unicorn Suite 1.24.00 BETA 2621"
)

# Constants
EEG_CHANNELS = 8
SAMPLING_RATE = 250

# Create LSL stream info
info = StreamInfo(
    name='UnicornEEG',
    type='EEG',
    channel_count=EEG_CHANNELS,
    nominal_srate=SAMPLING_RATE,
    channel_format='float32',
    source_id='unicorn_hybrid_black'
)

# Create outlet
outlet = StreamOutlet(info)

# Open Unicorn device
device_handle = ctypes.c_void_p()
unicorn.UNICORN_OpenDeviceByIndex(0, ctypes.byref(device_handle))

# Start acquisition
unicorn.UNICORN_StartAcquisition(device_handle)

print("Streaming Unicorn EEG via LSL...")

try:
    while True:
        buffer = (ctypes.c_float * EEG_CHANNELS)()
        unicorn.UNICORN_GetData(
            device_handle,
            ctypes.byref(buffer),
            ctypes.sizeof(buffer)
        )

        sample = np.array(buffer, dtype=np.float32)
        outlet.push_sample(sample.tolist())

        time.sleep(1 / SAMPLING_RATE)

except KeyboardInterrupt:
    print("Stopping stream...")

finally:
    unicorn.UNICORN_StopAcquisition(device_handle)
    unicorn.UNICORN_CloseDevice(device_handle)