# HarmonyOS端适配说明

为保证录制稳定性，**本插件在HarmonyOS平台进行了如下修改**：

​	**禁止在录制过程中切换前后摄像头**



在录像状态下调用CameraController.setDescriptionWhileRecording()将无效，并返回错误提示：

```
Camera switching is not supported while recording.
```

此修改仅影响HarmonyOS端，**在Android/IOS平台保持原有行为**。请开发者在使用此插件开发时注意平台差异，避免在录制状态中调用切换摄像头逻辑，或使用平台判断进行适配。