# ahk-context-snippet
> 代码片段助手。一般代码编辑器都带代码助手，但规则各不相同，也需要独立配置，因此实现一个公共的代码片段助手，可以猜测上下文语言环境、对代码片段进行整体缩进。


### 使用
1. 安装AutoHotKey软件
2. 双击contextCmd.ahk执行
4. 在任意可编辑界面(如记事本)输入 /for/  ，会自动替换会已定义的代码片段
4. 托盘右键->代码片段管理->对代码片段进行增删改查操作
5. 代码片段命令、内建命令(以-开头)、热键(快捷键)

    |命令|作用|
    |-|-|
    | /snippetName/ |查询代码片段并替换|
    | /-lang java/ |配置当前语言环境为java|
    | /-lang/ |查看当前语言环境|
    | /-lang guess/ |猜测当前窗口语言环境|
    | /-lang null/<br>/-lang none/ |清除上下文语言环境|
    | /-gui/|进入GUI界面, 进行代码片段管理|
    | /-on/|代码片段助手开启|
    | /-off/|代码片段助手关闭(书写路径时容易误触发, 可以先关闭)|
    | /-reload/|重启脚本|
    | Win + /|当前有选中文本, 则进行注释;<br>当前未选中文本, 则循环开启\关闭代码助手|



### 演示
仓库中已定义的代码片段[java - for]  
注意标识$pos$的位置
<div align=center><img height=60% width=60% src="https://github.com/bjc5233/ahk-context-code/raw/master/resources/demo.gif"/></div>
<div align=center><img height=60% width=60% src="https://github.com/bjc5233/ahk-context-code/raw/master/resources/demo2.gif"/></div>
<div align=center><img height=60% width=60% src="https://github.com/bjc5233/ahk-context-code/raw/master/resources/demo3.png"/></div>




### 语言查询优先级
1. 用户输入命令中显式指定  /java for/
2. 根据-lang命令来配置当前语言环境
3. 根据上下文猜测语言环境，优先查询该语言分类下的代码片段

    |环境|猜测的语言|
    |-|-|
    |cmd.exe|bat|
    |mintty.exe|git|
    |chrome.exe|js|
    |idea64.exe|java|
    |SciTE.exe|ahk|
    |从窗口标题解析|随缘|
4. 查询common分类下的代码片段






### 代码片段中可用变量
|变量名|含义|
|-|-|
|$datetime$|替换成当前日期时间，格式为[yyyy-MM-dd HH:mm:ss]|
|$face$|替换随机字符表情|
|$weather$|替换shanghai今日天气，格式为[shanghai 小雨 10℃/7℃ 东风]|
|$pos$|替换之后，光标自动定位到此处|
|$param$|输入/java for j/会将j作为替换所有$param$的地方|
|$clip$|替换成当前剪切板内容|



### TODO
1. 对于无法匹配情况，弹出下拉选项框由用户主动选择
2. bug描述: needBackClip设置true, /syso/ /trycatch/失效
3. 粘贴后的代码片段会多出一个换行符，考虑是否去除
4. 每周五展示历史输入命令排行榜[前二十]；创建内部指令统计当前命令hitting次数排行榜
5. 代码片段排序自定义[上移下移]
6. "C:\path\AHK\ahkLearn\temp\Autohotkey-Scripts\Scriptlet Library\Scriptlet Library.ahk"
7. win+/进行代码注释时，进行toggle注释处理
8. ahk匹配执行速度一般，后期考虑使用py实现


### 其他
1. 项目用于替代[ahk-context-snippet](https://github.com/bjc5233/ahk-context-snippet)