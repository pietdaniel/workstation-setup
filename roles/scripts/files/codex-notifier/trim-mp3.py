import sys
from pathlib import Path


def synchsafe(value):
    return ((value[0] & 0x7F) << 21) | ((value[1] & 0x7F) << 14) | ((value[2] & 0x7F) << 7) | (value[3] & 0x7F)


def frame_info(data, position):
    if position + 4 > len(data):
        return None
    header = int.from_bytes(data[position:position + 4], "big")
    if header >> 21 != 0x7FF:
        return None

    version = (header >> 19) & 0x3
    layer = (header >> 17) & 0x3
    bitrate_index = (header >> 12) & 0xF
    sample_rate_index = (header >> 10) & 0x3
    padding = (header >> 9) & 0x1
    if version == 1 or layer != 1 or bitrate_index in (0, 15) or sample_rate_index == 3:
        return None

    sample_rates = {
        3: (44100, 48000, 32000),
        2: (22050, 24000, 16000),
        0: (11025, 12000, 8000),
    }
    mpeg1_bitrates = (0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320)
    mpeg2_bitrates = (0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160)
    sample_rate = sample_rates[version][sample_rate_index]
    bitrate = (mpeg1_bitrates if version == 3 else mpeg2_bitrates)[bitrate_index] * 1000
    samples = 1152 if version == 3 else 576
    frame_length = ((144 if version == 3 else 72) * bitrate // sample_rate) + padding
    return frame_length, samples, sample_rate


source = Path(sys.argv[1])
destination = Path(sys.argv[2])
skip_ms = int(sys.argv[3])
data = source.read_bytes()

position = 0
if data.startswith(b"ID3") and len(data) >= 10:
    position = 10 + synchsafe(data[6:10])

while position + 4 <= len(data) and frame_info(data, position) is None:
    position += 1

first_frame = position
elapsed_ms = 0.0
while position + 4 <= len(data):
    info = frame_info(data, position)
    if info is None:
        position += 1
        continue
    frame_length, samples, sample_rate = info
    if elapsed_ms >= skip_ms:
        break
    elapsed_ms += samples * 1000.0 / sample_rate
    position += frame_length

if position >= len(data) or position == first_frame:
    destination.write_bytes(data)
else:
    destination.write_bytes(data[position:])
