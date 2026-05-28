# =============================================================================
# ALGAE PHOTOTAXIS ANALYSIS PIPELINE
# =============================================================================
# This script performs multi-step image analysis to track the movement of algae
# under different light conditions. It relies on the well-known tracking 
# package Trackpy : https://soft-matter.github.io/trackpy/v0.7/index.html
# Pipeline overview:
#   Load images → Build background → Process frames →
#   Test particles detection → Filter noise → Run featuring →
#   Link trajectories → Compute kinematics → Analyse by lightning condition


# =============================================================================
#%% 0 — Import packages
# =============================================================================
import matplotlib as mpl
import matplotlib.pyplot as plt

mpl.rc('figure', figsize=(10, 5))
mpl.rc('image', cmap='gray')

# Uncomment the lines below to install missing packages in your environment:
# import sys
# !{sys.executable} -m pip install numba pims trackpy opencv-python tqdm imagecodecs

import numpy as np
import numba                  # JIT compilation to speed up the tracking loop
import pandas as pd
from scipy.stats import norm  # Gaussian fit for mass histogram
import pims                   # Opens .tif / .avi image sequences
import trackpy as tp          # Particle tracking (based on Crocker-Grier algorithm)
import cv2                    # Image processing (blur, morphology, …)
from tqdm import tqdm         # Progress bar for long loops
import os
import imagecodecs

# =============================================================================
# %% 1 — Experiment parameters  ← EDIT THIS SECTION FOR EACH RECORDING
# =============================================================================
frames_path        = 'C:/Users/lejou/Documents/Thèse/Confs/MOB Cargese 2026/Test'      # Absolute path to the folder containing the image frames
conversion_pix_um  = 1 / 1   # Spatial calibration: micrometres per pixel (µm/px)
framerate          = 1       # Acquisition frame rate (frames per second)
filename           = 'Record'      # Common prefix shared by all frame files (e.g. "2024-01-15_10h30")
ext                = ''      # File extension without the dot (e.g. 'tif', 'png')

alga_diameter      = 15      # Expected apparent diameter of a single alga, in pixels.
                             # Must be an ODD integer; used by trackpy to set the
                             # band-pass filter kernel size.


# =============================================================================
# %% 2 — Build the list of frame paths and define the frame-reader function
# =============================================================================
# PIMS can open many image formats transparently.

@pims.pipeline
def gray(image):
    """Return the image unchanged (grayscale pipeline placeholder).
    Modify here to extract a specific channel, e.g. image[:, :, 1] for green."""
    return image


# Sort filenames so that frame N always comes before frame N+1.
# The key extracts the numeric suffix that follows `filename` in each file name.
frames_access = os.listdir(frames_path)
frames_access = sorted(
    frames_access,
    key=lambda x: (
        int(x.split(filename)[1].split('.' + ext)[0])
        if filename in x else float('inf')
    )
)


def frames(n):
    #Load and return frame number `n` as a 2-D numpy array
    frame_tmp = gray(pims.open(frames_path + frames_access[n]))
    return frame_tmp[0]   # pims wraps the image in a 1-element sequence


# =============================================================================
# %% 3 — Compute the static background
# =============================================================================
# Strategy: average a sparse subset of frames.
# Algae move between frames, so their signal averages out to near-zero,
# leaving only the static features of the field of view (dust, uneven
# illumination, camera fixed-pattern noise).

print('Creating background image …')

frame_space = 100                                   # Take one frame every `frame_space` frames
num_mean    = int(len(frames_access) / frame_space) # Total number of frames used for the mean

# Pre-allocate a 3-D stack: (height, width, num_mean)
image_add = np.zeros((frames(0).shape[0], frames(0).shape[1], num_mean))

for i in tqdm(range(num_mean)):
    image_add[:, :, i] = frames(i * frame_space)

background_image = np.mean(image_add, axis=2)  # background

plt.figure()
plt.title('Background image')
plt.imshow(background_image)
plt.colorbar()
plt.show()


# =============================================================================
# %% 4 — Single-frame image processing (test on frame 0)
# =============================================================================
# Steps applied to each frame before particle detection:
# raw → subtract background → absolute value → Gaussian blur

image1 = frames(0)                                                    # Raw frame
image2 = image1 - background_image                                    # Remove static background
image3 = np.abs(image2)                                               # Both bright and dark algae
                                                                      # become positive peaks
blur_size = 5                                                         # Kernel side length (px); must be odd
image4 = cv2.GaussianBlur(image3, (blur_size, blur_size),
                           cv2.BORDER_DEFAULT)                        # Smooth to reduce detection noise

plt.figure()
plt.title('Blurred background-subtracted frame (image4)')
plt.imshow(image4)
plt.show()


# =============================================================================
# %% 5 — First particle detection (parameter exploration)
# =============================================================================
# tp.locate finds circular bright features using a band-pass + centroid algorithm.
# invert=True  → particles are DARK on a BRIGHT background (raw or bg-subtracted)
# invert=False → particles are BRIGHT on a DARK background (abs / blurred)

f1 = tp.locate(image1, alga_diameter, invert=True)   # Raw image
f2 = tp.locate(image2, alga_diameter, invert=True)   # Background-subtracted
f3 = tp.locate(image3, alga_diameter, invert=False)  # Absolute value
f4 = tp.locate(image4, alga_diameter, invert=False)  # Blurred absolute value

plt.close()
# Overlay detected centroids (f4) on the raw image for visual validation
tp.annotate(f4, image1)


# =============================================================================
# %% 6 — Inspect the mass (integrated intensity) distribution
# =============================================================================
# Noise artefacts are detected as very faint, transient dots.
# They form a sharp peak at LOW mass values in the histogram.
# Real algae appear at HIGHER mass values.
# Fitting a Gaussian helps locate the noise peak and choose a threshold.

mass = f4['mass']
mu, std = norm.fit(mass)

plt.figure()
plt.hist(mass, bins=600, density=True, alpha=0.6, label='detected particles')

xmin, xmax = plt.xlim()
x = np.linspace(xmin, xmax, len(mass))
plt.plot(x, norm.pdf(x, mu, std), 'k', linewidth=2, label='Gaussian fit')

plt.xlabel('Integrated intensity (mass)')
plt.ylabel('Normalised count')
plt.title(r'Mass histogram — $\mu=%.2f$, $\sigma=%.2f$' % (mu, std))
plt.legend()
plt.show()

# Observation: expect a high-density spike near zero (noise) and a broader
# distribution at higher masses (algae). 

# =============================================================================
# %% 7 — Noise filtering: re-detect with a minimum mass threshold
# =============================================================================
# I_min is expressed as a multiple of the Gaussian standard deviation so that
# the threshold adapts automatically to each recording's contrast level.
# Adjust I_min depending on quality of detection

I_min = std * 1.5   # Minimum accepted integrated intensity. 

f4 = tp.locate(image4, alga_diameter, minmass=I_min, invert=False)
mu, std = norm.fit(f4['mass'])

plt.figure()
plt.hist(f4['mass'], bins=60, density=True, alpha=0.6, label='filtered particles')

xmin, xmax = plt.xlim()
x = np.linspace(xmin, xmax, len(mass))
plt.plot(x, norm.pdf(x, mu, std), 'k', linewidth=2, label='Gaussian fit')

plt.xlabel('Integrated intensity (mass)')
plt.ylabel('Normalised count')
plt.title(r'Filtered mass histogram — $\mu=%.2f$, $\sigma=%.2f$' % (mu, std))
plt.legend()
plt.show()

print(f'Intensity threshold I_min = {I_min:.2f}')


# =============================================================================
# %% 8 — Visual validation of detection parameters
# =============================================================================
# Display all four processing stages side-by-side and overlay the final
# detected centroids on the raw image to confirm detection quality.

plt.figure(figsize=(12, 6))

plt.subplot(2, 2, 1)
plt.imshow(image1)
plt.title('Raw image', pad=-60, fontsize=14)

plt.subplot(2, 2, 2)
plt.imshow(image2)
plt.title('Background-subtracted', pad=-60, fontsize=14)

plt.subplot(2, 2, 3)
plt.imshow(image3)
plt.title('Absolute value', pad=-60, fontsize=12)

plt.subplot(2, 2, 4)
plt.imshow(image4)
plt.title('Gaussian blurred', pad=-60, fontsize=12)

plt.tight_layout()

# Separate annotated figure: centroids detected in f4 drawn on the raw frame
tp.annotate(f4, image1)


# =============================================================================
# %% 9 — Full-recording particle detection loop
# =============================================================================
# The same processing pipeline (background subtraction → abs → blur) is
# applied to every frame. Results are concatenated into a single DataFrame
# that stores (x, y, mass, frame, …) for every detected particle.

def cleaning(frame):
    # Apply the standard pre-processing pipeline to a raw frame.

    img = frame - background_image          # Remove  background
    img = np.abs(img)                       # Make all peaks positive
    img = cv2.GaussianBlur(img, (blur_size, blur_size), cv2.BORDER_DEFAULT)
    return img

print('Detecting particles on all frames')

# Initialise with frame 0 (required before the concat loop)
f_total = tp.locate(cleaning(frames(0)), alga_diameter,
                    minmass=I_min, invert=False, characterize=False)
f_total['frame'] = 0

# Iterate over all remaining frames
for i in tqdm(range(1, len(frames_access))):
    tmp     = cleaning(frames(i))
    f_local = tp.locate(tmp, alga_diameter, minmass=I_min,
                        invert=False, characterize=True,
                        engine='numba')   # numba engine: faster on large datasets
    f_local['frame'] = i
    f_total = pd.concat([f_total, f_local])


# =============================================================================
# %% 10 — Particle linking (build trajectories)
# =============================================================================
# tp.link associates detections across consecutive frames using the
# nearest-neighbour algorithm. More details on 
# https://soft-matter.github.io/trackpy/v0.7/tutorial/prediction.html
# Two key parameters:
#   • displacement_range : maximum displacement (px) allowed between frames.
#                          Set to slightly above the typical inter-frame displacement.
#   • memory             : number of frames a particle may be undetected) before its 
#                          trajectory is terminated.

print('Linking particles into trajectories')

displacement_range = 5   # Maximum frame-to-frame displacement (px) — adjust to your system

track_total = tp.link(f_total, displacement_range, memory=2)

print('Tracking complete!')


# =============================================================================
# %% 11 — Trajectory filtering (remove short / spurious tracks)
# =============================================================================
# Short trajectories (< min_frames) are likely noise or algae that enter/leave
# the field of view. Keeping only long tracks improves kinematic estimates.

min_frames = 100   # Minimum track length (frames) to keep 

t_filter = tp.filter_stubs(track_total, min_frames)

print(f'Trajectories before filtering : {track_total["particle"].nunique()}')
print(f'Trajectories after  filtering : {t_filter["particle"].nunique()}')
t_filter.head()


# =============================================================================
# %% 12 — Compute instantaneous speed and orientation
# =============================================================================
# Kinematics are computed from differences between consecutive positions.
# Unit conversions are applied.

DF_alga = t_filter.copy()

# Convert pixel coordinates and frame index to physical units
DF_alga['x']      = t_filter['x'] * conversion_pix_um   # µm
DF_alga['y']      = t_filter['y'] * conversion_pix_um   # µm
DF_alga['time(s)'] = t_filter['frame'] / framerate       # seconds

# Sort so that diff() always compares temporally adjacent positions of the same particle
DF_alga = DF_alga.sort_values(['particle', 'time(s)'])

# Finite differences within each particle group (NaN for the first point of each track)
dx = DF_alga.groupby('particle')['x'].diff()        # µm
dy = DF_alga.groupby('particle')['y'].diff()        # µm
dt = DF_alga.groupby('particle')['time(s)'].diff()  # s

# Instantaneous speed: distance / time
DF_alga['speed'] = np.sqrt(dx**2 + dy**2) / dt     # µm/s

# Swimming angle: arctan2 convention → 0 = rightward, π/2 = upward
# The negative sign on dy allows to correct the y-axis pointing downward.
DF_alga['theta'] = np.arctan2(-dy, dx)              # radians, in [-π, π]


# =============================================================================
# %% 13 — Split data by illumination time window (Phototaxis class)
# =============================================================================
# The Phototaxis class creates sub-DataFrames, one per illumination interval. 
# Each interval is defined by its start time (s) and duration `window` seconds.

class Phototaxis:
    
    def __init__(self, data, time_switch, window=29):
        self.data = data
        self.t = {
            f: self.data[
                (self.data['time(s)'] >= f) & (self.data['time(s)'] < (f + window))
            ]
            for f in time_switch
        }


# Define the three illumination conditions:
#   t=0  s → no phototaxis (PT) light
#   t=30 s → low PT light intensity
#   t=90 s → high PT light intensity
PT = Phototaxis(DF_alga, time_switch=(0, 30, 90))


# =============================================================================
# %% 14 — Visualise trajectories per condition
# =============================================================================
# tp.plot_traj draws all tracks for the selected time window.
# Change the key (0, 30, or 90) to inspect a different condition.

tp.plot_traj(PT.t[0])   # Replace 0 with 30 or 90 to switch condition


# =============================================================================
# %% 15 — Speed distribution per illumination condition
# =============================================================================
# Compare speed distributions between the three light conditions.

plt.figure()
plt.hist(PT.t[0]['speed'],  bins=range(0, 350, 1), histtype='step', label='No PT light  (t=0 s)')
plt.hist(PT.t[30]['speed'], bins=range(0, 350, 1), histtype='step', label='Low PT light (t=30 s)')
plt.hist(PT.t[90]['speed'], bins=range(0, 350, 1), histtype='step', label='High PT light (t=90 s)')
plt.xlabel('Instantaneous speed (µm/s)')
plt.ylabel('Count')
plt.legend()
plt.title('Speed distribution under different light conditions')
plt.show()


# =============================================================================
# %% 16 — Swimming orientation per illumination condition (polar histograms)
# =============================================================================
# Compare orientation distributions between the three light conditions.

fig = plt.figure(figsize=(12, 4))

ax1 = fig.add_subplot(131, projection='polar')
ax1.hist(PT.t[0]['theta'],  bins=36, density=True, alpha=0.6)
ax1.set_ylim(0, 0.35)
ax1.set_title('No PT light\n(t=0 s)')

ax2 = fig.add_subplot(132, projection='polar')
ax2.hist(PT.t[30]['theta'], bins=36, density=True, alpha=0.6)
ax2.set_ylim(0, 0.35)
ax2.set_title('Low PT light\n(t=30 s)')

ax3 = fig.add_subplot(133, projection='polar')

ax3.hist(PT.t[90]['theta'], bins=36, density=True, alpha=0.6)
ax3.set_ylim(0, 0.35)
ax3.set_title('High PT light\n(t=90 s)')

fig.suptitle('Swimming orientation under different light conditions')
plt.tight_layout()
plt.show()