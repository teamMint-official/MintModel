# MintModel
Parameterized 3D Human Model (3DMM + SMPL)
See the detail of each part
Face: 3DMM, defined by Volker Blanz and Thomas Vetter in "A Morphable Model For The Synthesis Of 3D Faces" (SIGGRAPH 99)
Body: SMPL, https://smpl.is.tue.mpg.de/

## 1. Predefinition
Download the Mintmodel Core file from https://drive.google.com/drive/folders/11ZIALUX7B_V9vvOJAwKBkBgHCJBB8ECk?usp=sharing

### MintModel.mat?
MATLAB Data File that stores the core configuration variables of MintModel
```
ShapeDirs: Shape regressor of body part.
PoseDirs: Pose regressor of body part.
meanVerts: Basic template vertices. (x, y, z)
F: Basic template faces. (v1, v2, v3)
w_shp: Shape regressor of face part.
w_exp: Pose regressor of face part.
```

## 2. How to Use?
Run MintModel.m like below script
```
v = MintModel(M, beta, theta, Shape_Para, Exp_Para)
```

## 3. How to Make this Model?
Attach 3DMM Face to SMPL Body, with removing face.
See Section 3 of S.Ploumpis et. al. "Towards a complete 3D morphable model of the human head", TPAMI2020
