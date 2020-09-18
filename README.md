# OpenGL_3.0

## 介绍

本工程完全采用OpenGL ES 3.0的API进行实现，目的是更好的使用OpenGL相关功能并移植到移动端项目。

以示例为主，可以作为调参工具，也可以作为学习参考。

## 图片显示

* 将需要显示的图片转成纹理
* 纹理序号将会在渲染线程中传给GPU进行缓存
* OpenGL程序绘制纹理并光栅化显示到窗口

```
// 图片指定存储路径
NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"yourname" ofType:@"png"];
// 转换图片为OpenGL纹理ID
GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:imagePath options:@{GLKTextureLoaderOriginBottomLeft : @true, GLKTextureLoaderGenerateMipmaps : @true} error:NULL];
// 存储纹理
self.mTextureId = textureInfo.name;
// 纹理尺寸
_imageSize = CGSizeMake(textureInfo.width, textureInfo.height);
```

**图例一**

<div align=left><img width="300" height="600" src="example_1.png"/></div>

## 动画

* 通过绘制两张不同的图像
* 在切换图像过程中，编写shader，添加一些行为（如：旋转、渐变、缩放、移动等）
* 按指定帧率渲染每一帧图像，得到流畅的动画


**图例二**

<div align=left><img width="300" height="600" src="example_2.gif"/></div>


* 多张图片绘制时，可能需要修改透明度(需要开启混合模式, 会占用一定资源)
* 将时间作为参数传入shader，用于控制显示时长及效果
* 绘制第二张图片到窗口，用于替代第一张图，实现转场效果

```
- (void)redrawTexture
{
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    timeElapsed += [[NSString stringWithFormat:@"%f", self.timeSinceLastDraw] doubleValue];
    glUniform1f(_timeUniform, timeElapsed);
    glUniform1f(_chatrletUniform, 1.0);
    if (_textureId)
    {
         glActiveTexture(GL_TEXTURE3);
         glBindTexture(GL_TEXTURE_2D, _textureId);
         glUniform1i(_textureUniform, 3);
    }
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glDisable(GL_BLEND);
}
```
