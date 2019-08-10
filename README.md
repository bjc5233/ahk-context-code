# ahk-context-snippet
> 一般代码编辑器都自带代码助手，输入指定短语，替换称整段代码。但规则各不相同，因此实现一个系统级别的代码片段助手。


### 使用
1. 安装autoHotKey软件
2. 托盘菜单->代码片段管理->进入界面增加删除修改代码片段
3. 修改[needBackClip]，表示是否需要备份剪切板数据
3. 双击contextCmd.ahk执行
4. 在任意可输入的地方(如记事本)输入，  /for/，代码片段会被自动替换

### 特点
1. 任意可输入界面。终端、记事本、notepad++、sublime、chromeConsole、idea...
2. 手动输入的命令在替换成代码片段的同时自动清除
3. 根据光标所在行，行首空格数量，自动对代码片段整体缩进
4. 当前是cmd窗口, 不显示指定语言，则设置lang为bat；当前是mintty窗口，不显示指定语言，则设置lang为git




### 演示
仓库中已定义的代码片段[...\snippets\java\for.java]  
注意标识$pos$的位置

```java
for (Integer i : list) {
    System.out.println($pos$);
}

for (int i = 0; i < list.size(); i++) {
    System.out.println(list.get(i));
}

Iterator<Integer> it = list.iterator();
while (it.hasNext()) {
    int i = (Integer) it.next();
    System.out.println(i);
}
```

<div align=center><img src="https://github.com/bjc5233/ahk-context-code/raw/master/resources/demo.gif"/></div>
<div align=center><img src="https://github.com/bjc5233/ahk-context-code/raw/master/resources/demo2.gif"/></div>
<div align=center><img src="https://github.com/bjc5233/ahk-context-code/raw/master/resources/demo3.png"/></div>




### 语言查询优先级
1. 用户输入命令中显式指定  /java for/
2. 用户输入命令lang来配置当前语言环境
3. 根据上下文猜测语言环境，优先查询该语言分类下的代码片段
4. 查询common分类下的代码片段

```
/lang/ 查看当前语言环境
/lang null/ 清除当前语言环境
/lang none/ 清除当前语言环境
/lang java/ 配置当前语言环境为java
/lang guess/ 猜测当前语言环境
```




### 代码片段中可用变量
1. $datetime$ --> 替换成当前日期时间，格式为[yyyy-MM-dd HH:mm:ss]
2. $face$ --> 替换随机字符表情
3. $weather$ --> 替换shanghai今日天气，格式为[shanghai 小雨 10℃/7℃ 东风]
4. $pos$ --> 替换之后，光标自动定位到此处
5. $param$ --> 输入/java for j/会将j作为替换所有$param$的地方
6. $clip$ --> 替换成当前剪切板内容





### TODO
1. 对于无法匹配情况，弹出下拉选项框由用户主动选择
2. bug描述: needBackClip设置true, /syso/ /trycatch/失效
3. 粘贴后的代码片段会多出一个换行符，考虑是否去除
4. 每周五展示历史输入命令排行榜[前二十]；创建内部指令统计当前命令hitting次数排行榜
5. 代码片段排序自定义[上移下移]


### 其他
1. 项目用于替代[ahk-context-snippet](https://github.com/bjc5233/ahk-context-snippet)