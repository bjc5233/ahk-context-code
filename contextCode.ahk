;说明
;  上下文代码片段助手；监听//之间输入的命令
;  Win+/ 猜测当前代码语言, 并增加注释
;配置
;  1.托盘菜单->代码片段管理->进入界面增加删除修改代码片段
;  2.needBackClip是否需要备份剪切板
;注意
;  1.console界面会将换行符表示成执行命令, 因此一般用于console中执行的代码片段最好是一行
;TODO
;  1.对于无法匹配情况，弹出下拉选项框由用户主动选择
;  2.bug描述: needBackClip设置true, /syso/ /trycatch/失效
;  3.粘贴后的代码片段会多出一个换行符，考虑是否去除
;========================= 环境配置 =========================
#Persistent
#NoEnv
#SingleInstance, Force
DetectHiddenWindows, On
SetTitleMatchMode, 2
SetBatchLines, -1
SetKeyDelay, -1
StringCaseSense, off
CoordMode, Menu
#Include <JSON> 
#Include <PRINT>
#Include <TIP>
#Include <DBA>
;========================= 环境配置 =========================

;========================= 变量配置 =========================
global currentDB := Object()
global langsFull := Object()         ;[java, bat, ...]
global langCodesFull := Object()     ;<langName, <codeName, codeObj>>
global settingLang :=
global userInput :=
global searchLang :=
global searchLangMode :=
global searchKey :=
global searchParam :=
global searchCode :=
global codePrefixBlankStr :=
global codePrefixBlankLen :=
global codeEditorIsConsole := false
global codeVar :=
global codeNeedLeftKeyCount := 
global codeNeedUpKeyCount :=
global codeNeedRightKeyCount :=
global codeLinePosIndex :=

global needBackClip := false
global curProcessName :=
global curId :=
global curTitle :=

global langAnnotateMap := Object()
DBConnect()
MenuTray()
LoadLangCodes()
;========================= 变量配置 =========================


;========================= 输入命令检测 =========================
~/::
    Input, userInput, V T10, /,
    if (!userInput || InStr(userInput, "`n", true))             ;如输入文本中包含换行, 则不是有效命令
        return
    userInput := RegExReplace(Trim(userInput), "\s+", " ")      ;去除首位空格, 将字符串内多个连续空格替换为单个空格
    if (!userInput)
        return
    FetchWinInfo()
    if (SubStr(userInput, 1, 4) == "lang") {
        ParseLangCmd()
    } else {
        ParseUserInput()             ;从用户输入解析出[语言类型、代码key]\[内部指令、指令参数]
        if (!MatchCode())            ;无匹配代码片段时退出
            return
        CalcCodeIndent()             ;计算行缩进空格
        ParseCodeLineCmd()           ;代码片段光标\行内参数处理
        SimulateSendKey()            ;模拟按键
    }
return
#/::
    FetchWinInfo()
    AnnotateCode()
return
;========================= 输入命令检测 =========================



;========================= 构建界面-主 =========================
global LangNameLVHwnd :=
global CodeNameLVHwnd :=
global LangNameLV :=
global CodeNameLV :=
global CodeNameEdit :=
global CodeDescEdit :=
global CodeContentEdit :=
global CodeContentEdit :=
global GuiSaveButton :=
global CodeOperateType :=
global GuiSelectLangId :=
global GuiSelectLangName :=
global GuiSelectCodeId :=
global GuiSelectCodeName :=
Gui(ItemName, ItemPos, MenuName){
    Gui, Gui:New
    Gui, Gui:Font, s10, Microsoft YaHei
    Gui, Gui:Add, ListView, w200 r26 Readonly AltSubmit cFFFFFF Background142F43 HScroll -Hdr -Multi HwndLangNameLVHwnd vLangNameLV gGuiLangNameLVHandler, id|name
    LV_ModifyCol(1, 0)
    LV_ModifyCol(2, 180)
    Gui, Gui:Add, ListView, w200 r26 x+0 Readonly AltSubmit Grid BackgroundFFFFFF HScroll -Hdr -Multi HwndCodeNameLVHwnd vCodeNameLV gGuiCodeNameLVHandler, id|name
    LV_ModifyCol(1, 0)
    LV_ModifyCol(2, 180)
    Gui, Gui:Add, GroupBox, x+10 y-0 w450 h575
    Gui, Gui:Add, Text, xp+10 yp+25, 名称：
    Gui, Gui:Add, Edit, w380 x+0 vCodeNameEdit
    Gui, Gui:Add, Text, x+-420 y+15, 描述：
    Gui, Gui:Add, Edit, w380 x+0 vCodeDescEdit
    Gui, Gui:Add, Text, x+-420 y+15, 代码：
    Gui, Gui:Add, Edit, w380 r22 x+0 vCodeContentEdit
	Gui, Gui:Add, Button, w50 Hidden vGuiSaveButton gGuiSaveButtonHandler, 保存
    Gui, Gui:Add, StatusBar
    Gui, Gui:Show, , 代码片段管理
    SB_SetParts(11, 200, 200)
    FillLangName()
}
GuiGuiContextMenu(GuiHwnd, CtrlHwnd, EventInfo, IsRightClick, X, Y) {
    if (CtrlHwnd == LangNameLVHwnd) {
        Gui, Gui:Default
        Gui, ListView, LangNameLV
        rowNum := LV_GetNext(0, "Focused")
        if (rowNum) {
            Menu, LangNameMenu, Enable, 删除
        } else {
            Menu, LangNameMenu, Disable, 删除
        }
        Menu, LangNameMenu, Show
    } else if (CtrlHwnd == CodeNameLVHwnd) {
        Gui, Gui:Default
        Gui, ListView, CodeNameLV
        rowNum := LV_GetNext(0, "Focused")
        if (rowNum) {
            Menu, CodeNameMenu, Enable, 修改
            Menu, CodeNameMenu, Enable, 删除
        } else {
            Menu, CodeNameMenu, Disable, 修改
            Menu, CodeNameMenu, Disable, 删除
        }
        Menu, CodeNameMenu, Show
    }
}

GuiLangNameLVHandler(CtrlHwnd, GuiEvent, EventInfo) {
	if (GuiEvent == "Normal") {
        if (!EventInfo)
            return
        Gui, Gui:Default
        Gui, ListView, LangNameLV
        LV_GetText(langId, EventInfo, 1)
        LV_GetText(langName, EventInfo, 2)
        FillCodeName(langId, langName, "name")
        GuiControl,, CodeNameEdit
        GuiControl,, CodeDescEdit
        GuiControl,, CodeContentEdit
        GuiSelectLangId := langId
        GuiSelectLangName := langName
	}
}
GuiCodeNameLVHandler(CtrlHwnd, GuiEvent, EventInfo) {
	if (GuiEvent == "Normal") {
        if (!EventInfo)
            return
        Gui, Gui:Default
        Gui, ListView, CodeNameLV
        LV_GetText(codeId, EventInfo, 1)
        code := DBCodeDetail(codeId)
        GuiControl,, CodeNameEdit, % code.name
        GuiControl,, CodeDescEdit, % code.desc
        GuiControl,, CodeContentEdit, % code.content
        GuiControl, Hide, GuiSaveButton
        CodeOperateType := "read"
        GuiSelectCodeId := codeId
        GuiSelectCodeName := code.name
        SB_SetText("  查看 " GuiSelectLangName "->" GuiSelectCodeName, 4)
	}
}
GuiSaveButtonHandler(CtrlHwnd, GuiEvent, EventInfo) {
    Gui, Gui:Default
    Gui, Gui:Submit, NoHide
    if (!CodeNameEdit) {
        MsgBox, 必须填写名称
        return
    }
    if (!CodeContentEdit) {
        MsgBox, 必须填写代码
        return
    }
    if (CodeOperateType == "add") {
        Gui, ListView, LangNameLV
        rowNum := LV_GetNext(0, "Focused")
        if (!rowNum)
            return
        LV_GetText(langId, rowNum, 1)
        codeObj := Object()
        codeObj.name := CodeNameEdit
        codeObj.desc := CodeDescEdit
        codeObj.content := CodeContentEdit
        codeObj.langId := langId
        codeId := DBCodeNew(codeObj)
        Gui, ListView, CodeNameLV
        LV_Add("Focus", codeId, CodeNameEdit)
    } else if (CodeOperateType == "edit") {
        Gui, ListView, CodeNameLV
        rowNum := LV_GetNext(0, "Focused")
        if (!rowNum)
            return
        LV_GetText(codeId, rowNum, 1)
        codeObj := Object()
        codeObj.name := CodeNameEdit
        codeObj.desc := CodeDescEdit
        codeObj.content := CodeContentEdit
        codeObj.id := codeId
        if (!DBCodeUpdate(codeObj)) {
            MsgBox, 修改失败！
        }
        LV_Modify(rowNum, "", , CodeNameEdit)
    }
    GuiControl, Hide, GuiSaveButton
}
;========================= 构建界面-主 =========================


;========================= 构建界面-新建语言 =========================
global CodeNewLangEdit :=
GuiNewLang() {
    Gui, CodeNewLangGui:New
	Gui, CodeNewLangGui:Margin, 20, 20
	Gui, CodeNewLangGui:Font, s10, Microsoft YaHei
	Gui, CodeNewLangGui:Add, Text, xm+10 y+15 w60, 名称：
	Gui, CodeNewLangGui:Add, Edit, x+5 yp-3 w200 vCodeNewLangEdit,
	Gui, CodeNewLangGui:Add, Button, Default xm+80 y+15 w50 gGuiNewLangSave, 确定
	Gui, CodeNewLangGui:Add, Button, x+20 w50 gGuiNewLangCancel, 取消
	Gui, CodeNewLangGui:Show, ,添加新语言
}
GuiNewLangSave(CtrlHwnd, GuiEvent, EventInfo) {
    Gui, CodeNewLangGui:Default
    Gui, CodeNewLangGui:Submit, NoHide
    if (!CodeNewLangEdit)
        return
    langName := CodeNewLangEdit
    langNum := DBLangCount(langName)
    if (langNum) {
        MsgBox, % "已存在[" langName "]语言分类"
    } else {
        langId := DBLangNew(langName)
        Gui, Gui:Default
        Gui, ListView, LangNameLV
        LV_Add("", langId, langName)
        Gui, CodeNewLangGui:Hide
    }
}
GuiNewLangCancel(CtrlHwnd, GuiEvent, EventInfo) {
    Gui, CodeNewLangGui:Hide
}
;========================= 构建界面-新建语言 =========================


;========================= 构建界面-菜单 =========================
MenuTray() {
	Menu, Tray, NoStandard
	Menu, Tray, add, 代码片段管理, Gui
	Menu, Tray, add
	Menu, Tray, add, 重启, MenuTrayReload
	Menu, Tray, add, 退出, MenuTrayExit
    Menu, Tray, Default, 代码片段管理
    
    Menu, LangNameMenu, Add, 刷新, LangNameMenuHandler
    Menu, LangNameMenu, Icon, 刷新, SHELL32.dll, 239
    Menu, LangNameMenu, Add, 新增, LangNameMenuHandler
    Menu, LangNameMenu, Icon, 新增, SHELL32.dll, 1
    Menu, LangNameMenu, Add
    Menu, LangNameMenu, Add, 删除, LangNameMenuHandler
    Menu, LangNameMenu, Icon, 删除, SHELL32.dll, 132
    
    
    Menu, CodeNameMenu, Add, 刷新, CodeNameMenuHandler
    Menu, CodeNameMenu, Icon, 刷新, SHELL32.dll, 239
    Menu, CodeNameMenu, Add, 新增, CodeNameMenuHandler
    Menu, CodeNameMenu, Icon, 新增, SHELL32.dll, 1
    Menu, CodeNameMenuSub, Add, 名称, CodeNameMenuHandler, :CodeNameMenu
    Menu, CodeNameMenuSub, Add, 名称(降序), CodeNameMenuHandler, :CodeNameMenu
    Menu, CodeNameMenuSub, Add, 时间, CodeNameMenuHandler, :CodeNameMenu
    Menu, CodeNameMenuSub, Add, 时间(降序), CodeNameMenuHandler, :CodeNameMenu
    Menu, CodeNameMenu, Add, 排序, :CodeNameMenuSub
    Menu, CodeNameMenu, Add
    Menu, CodeNameMenu, Add, 修改, CodeNameMenuHandler
    Menu, CodeNameMenu, Icon, 修改, SHELL32.dll, 134
    Menu, CodeNameMenu, Add, 删除, CodeNameMenuHandler
    Menu, CodeNameMenu, Icon, 删除, SHELL32.dll, 132
}
MenuTrayReload(ItemName, ItemPos, MenuName) {
    Reload    
}
MenuTrayExit(ItemName, ItemPos, MenuName) {
    currentDB.Close()
    ExitApp
}
LangNameMenuHandler(ItemName, ItemPos, MenuName) {
    if (ItemName == "刷新") {
        Gui, Gui:Default
        Gui, ListView, LangNameLV
        LV_Delete()
        Gui, ListView, CodeNameLV
        LV_Delete()
        FillLangName()
    } else if (ItemName == "新增") {
        GuiNewLang()
    } else if (ItemName == "删除") {
        Gui, Gui:Default
        Gui, ListView, LangNameLV
        rowNum := LV_GetNext(0, "Focused")
        if (!rowNum)
            return
        LV_GetText(langId, rowNum, 1)
        LV_GetText(langName, rowNum, 2)
        codeNum := DBCodeCount(langId)
        if (codeNum) {
            MsgBox, % "[" langName "]语言分类下有[" codeNum "]个代码，不能删除"
        } else {
            MsgBox, 1, 删除, % "是否删除[" langName "]？"
            IfMsgBox OK
            {
                DBLangDel(langId)
                LV_Delete(rowNum)
            }
        }
    }
}
CodeNameMenuHandler(ItemName, ItemPos, MenuName) {
    Gui, Gui:Default
    if (MenuName == "CodeNameMenu") {
        if (ItemName == "刷新") {
            Gui, ListView, LangNameLV
            rowNum := LV_GetNext(0, "Focused")
            if (!rowNum)
                return
            LV_GetText(langId, rowNum, 1)
            LV_GetText(langName, rowNum, 2)
            Gui, ListView, CodeNameLV
            LV_Delete()
            FillCodeName(langId, langName, "name")
            GuiControl,, CodeNameEdit
            GuiControl,, CodeDescEdit
            GuiControl,, CodeContentEdit
            GuiControl, Hide, GuiSaveButton
        } else if (ItemName == "新增") {
            GuiControl,, CodeNameEdit
            GuiControl,, CodeDescEdit
            GuiControl,, CodeContentEdit
            GuiControl, Show, GuiSaveButton
            GuiControl, Focus, CodeNameEdit
            CodeOperateType := "add"
            SB_SetText("  新增 " GuiSelectLangName "->?", 4)
        } else if (ItemName == "修改") {
            GuiControl, Show, GuiSaveButton
            GuiControl, Focus, CodeNameEdit
            CodeOperateType := "edit"
            SB_SetText("  修改 " GuiSelectLangName "->" GuiSelectCodeName, 4)
        } else if (ItemName == "删除") {
            Gui, ListView, CodeNameLV
            rowNum := LV_GetNext(0, "Focused")
            if (!rowNum)
                return
            LV_GetText(codeId, rowNum, 1)
            LV_GetText(codeName, rowNum, 2)
            MsgBox, 1, 删除, % "是否删除[" codeName "]？"
            IfMsgBox OK
            {
                DBCodeDel(codeId)
                LV_Delete(rowNum)
                GuiControl,, CodeNameEdit
                GuiControl,, CodeDescEdit
                GuiControl,, CodeContentEdit
                SB_SetText("  ", 4)
            }
        }
    } else if (MenuName == "CodeNameMenuSub") {
        Gui, ListView, LangNameLV
        rowNum := LV_GetNext(0, "Focused")
        if (!rowNum)
            return
        LV_GetText(langId, rowNum, 1)
        LV_GetText(langName, rowNum, 2)
        Gui, ListView, CodeNameLV
        LV_Delete()
        if (ItemName == "名称") {
            FillCodeName(langId, langName, "name")
        } else if (ItemName == "名称(降序)") {
            FillCodeName(langId, langName, "name desc")
        } else if (ItemName == "时间") {
            FillCodeName(langId, langName, "datetime")
        } else if (ItemName == "时间(降序)") {
            FillCodeName(langId, langName, "datetime desc")
        }
        GuiControl,, CodeNameEdit
        GuiControl,, CodeDescEdit
        GuiControl,, CodeContentEdit
        GuiControl, Hide, GuiSaveButton
    }
}
;========================= 构建界面-菜单 =========================





;========================= 公共函数 =========================
LoadLangCodes() {
    langs := DBLangFind()
    for index, lang in langs {
        codes := DBCodeFind(lang.id)
        if (!codes.Length())
            continue
        langsFull.Push(lang.name)
        oneLangCodes := Object()
        for index, code in codes {
            oneLangCodes[code.name] := code
        }
        langCodesFull[lang.name] := oneLangCodes
    }
    
    langAnnotateMap := Object()
    langAnnotateMap["java"] := "//"
    langAnnotateMap["bat"] := "::"
    langAnnotateMap["ahk"] := ";"
    langAnnotateMap["vbs"] := "'"
    langAnnotateMap["py"] := "#"
}

FetchWinInfo() {
    ;根据当前窗口title、编辑文件后缀、进程、ahk_id，判断当前所处的语言环境，提供更好的代码帮助
    WinGet, curProcessName, ProcessName, A
    WinGet, curId, ID, A
    WinGetTitle, curTitle, ahk_id %curId%
}

ParseLangCmd() {
    userInputArray := StrSplit(userInput, A_Space)
    userInputCmd := userInputArray[2]
    if (userInputCmd) {
        if (userInputCmd == "null" or userInputCmd = "none") {
            settingLang =
            tip("清除上下文语言环境 !")
        } else if (userInputCmd = "guess") {
            searchLang := GuessLang()
            if (searchLang)
                tip("猜测当前语言环境为[" searchLang "] !")
            else
                tip("无法猜测出当前语言环境 !")
        } else if (HasElement(langsFull, userInputCmd)) {
            settingLang := userInputCmd
            tip("设置上下文语言环境为[" userInputCmd "] !") ;字符串之间以空格隔开就是字符串连接操作
        } else {
            settingLang := userInputCmd
            tip("配置成功，但仓库中未配置[" userInputCmd "]语言代码片段 !")
        }
    } else {
        if (settingLang)
            tip("当前上下文语言环境为[" settingLang "] !")
        else
            tip("未配置上下文语言环境 !")
    }
}

ParseUserInput() {
    ;当前语言环境猜测优先级
    ;  1.用户输入显式指定 - /java for/
    ;  2.用户输入上下文语言配置命令
    ;      /lang java/ 上下文语言配置为java
    ;      /lang/      取消上下文语言配置
    ;  3.通过编辑器标题中文件后缀 - /for/
    searchLang := searchLangMode := searchKey := searchParam := ""
    userInputArray := StrSplit(userInput, A_Space)
    userInputArrayLen := userInputArray.Length()
    if (userInputArrayLen == 1) {
        searchKey := userInput
    } else if (userInputArrayLen >= 2) {
        if (HasElement(langsFull, userInputArray[1])) {
            ;用户输入命令首元素是lang指令 - 例如[java for param]
            searchLang := userInputArray[1]
            searchLangMode = inline
            searchKey := userInputArray[2]
            if (userInputArrayLen == 3)
                searchParam := userInputArray[3]
        } else {
            ;用户输入命令首元素是key指令, 未指定具体lang - 例如[for param]
            searchKey := userInputArray[1]
            searchParam := userInputArray[2]
        }
    }
    ;尝试配置中读取配置中的lang
    if (!searchLang) {
        if (settingLang) {
            searchLang := settingLang
            searchLangMode = setting
        }
    }
    ;尝试自动检测环境lang
    if (!searchLang)
        searchLang := GuessLang()
}

MatchCode() {
    ;snippet查询匹配优先级
    ;  1.指定lang则从该语言分类下寻找，找不到则从common分类下寻找
    ;  2.未指定lang，从common分类下寻找
    ;  4.从非[当前lang分类\common分类]下寻找
    ;  5.仍然无法匹配，则放弃
    searchCode :=
    snippetMatchFlag := false
    snippetMatchLang :=
    ;指定lang分类下查询
    if (searchLang) {
        singleLangCodes := langCodesFull[searchLang]
        if (singleLangCodes) {
            searchCodeObj := singleLangCodes[searchKey]
            if (searchCodeObj) {
                snippetMatchFlag := true
                snippetMatchLang := searchLang
                searchCode := searchCodeObj["content"]
            }
        }
    }
    ;common分类下查询
    if (!searchLang || snippetMatchFlag == false) {
        commonSingleLangCodes := langCodesFull["common"]
        searchCodeObj := commonSingleLangCodes[searchKey]
        if (searchCodeObj) {
            snippetMatchFlag := true
            snippetMatchLang = common
            searchCode := searchCodeObj["content"]
        }
    }
    ;其他分类下查询
    if (snippetMatchFlag == false) {
        for index, element in langsFull {
            if (element == searchLang || element = "common")
                continue
            singleLangSnippets := langCodesFull[element]
            searchCodeObj := singleLangSnippets[searchKey]
            if (searchCodeObj) {
                snippetMatchFlag := true
                snippetMatchLang := element
                searchCode := searchCodeObj["content"]
                break
            }
        }
    }
    ;所有分类中都未匹配成功
    if (snippetMatchFlag == false) {
        tip("没有匹配的代码片段 !")
        return false
    }
    return true
}
CalcCodeIndent() {
    ;获取当前编辑器所在行文本，计算前缀空格\TAB数量，为code中的每行增加对应的空格前缀
    ;注意
    ;  1.snippet源码中代码空格前缀不用加，这里计算
    ;  2.snippet源码中TAB要转为4个空格   因为不同的编辑器，对待TAB策略不同[自动转n空格\保持TAB]，会导致codeNeedRightKeyCount错误
    codePrefixBlankLen := 0
    codePrefixBlankStr := ""
    codeEditorIsConsole := false
    if (curProcessName == "notepad.exe") {
        ControlGet, curLineNum, CurrentLine, , Edit1, ahk_id %curId%
        ControlGet, curLine, Line, %curLineNum%, Edit1, ahk_id %curId%
        RegExMatch(curLine, "^\s+", codePrefixBlankStr)
    } else if (curProcessName == "cmd.exe" || curProcessName == "mintty.exe") {
        codeEditorIsConsole := true
    } else {
        clipboard = ; 清空剪贴板
        SendInput, +{Home}+{Home}^c{Right}
        ClipWait
            RegExMatch(Clipboard, "^\s+", codePrefixBlankStr)
    } 
    if (codePrefixBlankStr) {
        ;将TAB替换成4个空格
        ;StringReplace, codePrefixBlankStr, codePrefixBlankStr, %A_Tab%, %A_Space%%A_Space%%A_Space%%A_Space%, All
        StringLen, codePrefixBlankLen, codePrefixBlankStr
    }
}


ParseCodeLineCmd() {
    ;创建代码片段时
    ;  1.通过$pos$指定光标位置（最多一个）
    ;  2.设置$param$，从用户输入中的参数读取替换（多个）
    ;
    ;  for (int $param$ = 0; $param$ < list.size(); $param$++) {
    ;      System.out.println(list.get($pos$));
    ;      System.out.println($param$);
    ;  }
    ;注意
    ;  console界面中, 换行符会被当成执行命令, 对于多行代码片段无法准确定位到$pos$位置(除非是代码最后一行)
    codeLineMax := codeVar := codeLine := codeLinePosIndex := codeLinePosIndex2 := codeNeedUpKeyCount := codeNeedRightKeyCount := codeNeedLeftKeyCount := ""
    Loop, parse, searchCode, `r`n
        codeLineMax := A_Index
    if (!codeLineMax) {
        tip("代码片段文件存在, 但内容为空 !")
        return
    }
    Loop, parse, searchCode, `r`n
    {
        codeLine := A_LoopField
        if (InStr(codeLine, "$datetime$", true)) {
            FormatTime, datetime, , yyyy-MM-dd HH:mm:ss
            codeLine := StrReplace(codeLine, "$datetime$", datetime)
        }
        if (InStr(codeLine, "$clip$", true)) {
            codeLine := StrReplace(codeLine, "$clip$", Clipboard)
        }
        if (InStr(codeLine, "$face$", true)) {
            face := GetFace()
            codeLine := StrReplace(codeLine, "$face$", face)
        }
        if (InStr(codeLine, "$weather$", true)) {
            weather := GetWeather()
            codeLine := StrReplace(codeLine, "$weather$", weather)
        }
        if (InStr(codeLine, "$param$", true)) {
            if (searchParam)
                codeLine := StrReplace(codeLine, "$param$", searchParam)
            else
                codeLine := StrReplace(codeLine, "$param$")
        }
        if (InStr(codeLine, "$pos$", true)) {
            if (codeEditorIsConsole && A_Index == codeLineMax) {
                codeLinePosIndex2 := InStr(codeLine, "$pos$", true,  0)
                codeLine := StrReplace(codeLine, "$pos$")
                codeNeedLeftKeyCount := StrLen(codeLine) - codeLinePosIndex2 + 2  ;console代码片段最后会自动添加空格, 因此需加2
            } else {
                codeLinePosIndex := A_Index
                codeLinePosIndex2 := InStr(codeLine, "$pos$", true) + codePrefixBlankLen
                codeLine := StrReplace(codeLine, "$pos$")
            }
        }
        ;行位符号
        if (codeEditorIsConsole) {
            if (A_Index == codeLineMax)
                codeVar := codeVar codePrefixBlankStr codeLine
            else
                codeVar := codeVar codePrefixBlankStr codeLine "`r"
        } else {
            codeVar := codeVar codePrefixBlankStr codeLine "`r`n"
        }
    }
    if (codeLinePosIndex) {
        codeNeedUpKeyCount := codeLineMax - codeLinePosIndex + 1
        codeNeedRightKeyCount := codeLinePosIndex2 - 1
    }
}

SimulateSendKey() {
    codeNeedBackKeyCount := StrLen(userInput) + 2    ;//符号也需要计算在退格值内，自加2
    if (needBackClip)
        savedClip := ClipboardAll   ;备份剪贴板数据

    WinGet, curId2, ID, A
    isWinChanged := (curId == curId2 ? false : true)    ;窗口发生变法时，在新窗口中不需要退格处理
    if (isWinChanged) {
        if (codeEditorIsConsole) {
            SendInput, {Raw}%codeVar%%A_Space%
            if (codeNeedLeftKeyCount)
                SendInput, {left %codeNeedLeftKeyCount%}
        } else {
            Clipboard := codeVar
            if (codeLinePosIndex)
                SendInput, ^v{up %codeNeedUpKeyCount%}{right %codeNeedRightKeyCount%}
            else
                SendInput, ^v
        }
    } else {
        if (codeEditorIsConsole) {
            ;console代码片段最后会自动添加空格, 方便用户书写后续命令
            SendInput, {backspace %codeNeedBackKeyCount%}{Raw}%codeVar%%A_Space%
            if (codeNeedLeftKeyCount)
                SendInput, {left %codeNeedLeftKeyCount%}
        } else {
            Clipboard := codeVar
            if (codeLinePosIndex)
                SendInput, {backspace %codeNeedBackKeyCount%}^v{up %codeNeedUpKeyCount%}{right %codeNeedRightKeyCount%}
            else
                SendInput, {backspace %codeNeedBackKeyCount%}^v
        }
    }
    
    if (needBackClip) {
        Clipboard := savedClip ; 恢复剪贴板为原来的内容
        savedClip :=           ; 释放内存
    }
}

AnnotateCode() {
    clipboard =
    SendInput, ^c
    ClipWait, 1
    code := Clipboard
    RegExMatch(code, "^\s+", codePrefixBlankStr)
    langAnnotate := GetLangAnnotate()
    codePrefixBlankStr2 := codePrefixBlankStr langAnnotate
    code2 := ""
    Loop, parse, code, `n
    {
        codeLine := RegExReplace(A_LoopField, "^" codePrefixBlankStr, codePrefixBlankStr2)
        code2 := code2 codeLine
    }
    Clipboard := code2
    SendInput, ^v
}

GetLangAnnotate() {
    lang := (settingLang ? settingLang : GuessLang())
    if (!lang)
        lang := "java"
    langAnnotate := langAnnotateMap[lang]
    if (!langAnnotate)
        langAnnotate := "//"
    return langAnnotate
}

HasElement(array, searchElement) {
	for index, element in array {
		if (element == searchElement)
			return true
	}
	return false
}
GuessLang() {
    if (curProcessName == "cmd.exe") {
        searchLang = bat
        searchLangMode = auto
    } else if (curProcessName == "mintty.exe") {
        searchLang = git
        searchLangMode = auto
    } else if (curProcessName == "chrome.exe") {
        searchLang = js
        searchLangMode = auto
    } else if (curProcessName == "idea64.exe") {
        searchLang = java
        searchLangMode = auto
    } else {
        FoundPos := RegExMatch(curTitle, "U)\..* ", postfix)
        StringReplace, postfix, postfix, %A_Space%, , All
        StringReplace, searchLang, postfix, ., , All
        if (searchLang)
            searchLangMode = auto
    }
	return searchLang
}
GetWeather() {
    ;天气接口提供 https://www.seniverse.com/
    key = qyqwrrtwehqfvren
    location = shanghai
    FormatTime, dateStr, , yyyy-MM-dd
    jsonFilePath = %A_Temp%\weather.%dateStr%.json
    IfNotExist, %jsonFilePath%
        URLDownloadToFile, https://api.seniverse.com/v3/weather/now.json?key=%key%&location=%location%&language=en&unit=c, %jsonFilePath%
    
    jsonFile := FileOpen(jsonFilePath, "r")
    jsonStr := JSON.Load(jsonFile.Read())
    jsonFile.Close()
    weatherNow := jsonStr.results[1]["now"]
    weatherLocation := jsonStr.results[1]["location"]
    weatherStr := weatherLocation.name " " weatherNow.text " " weatherNow.temperature "℃"
    return %weatherStr%
}
GetFace() {
    _faces := ["(""▔□▔)", "(︶︿︶)=凸", "(ΘｏΘ)", "(=￣ω￣=)", "Σ( ° △ °|||)︴", "(￣▽￣)", "(づ￣3￣)づ", "(~￣▽￣)~", "(^>﹏^<)", "●ω●", "*^_^*", "T_T", "-_-#", "^ω^", "←_←", "→_→", "555~", "≥﹏≤", "(>_<)", "⊙ω⊙", "(>﹏<)", "(╯3╰)", "(°ο°)", "●﹏●", "●︿●", "(=^.^=)", "(=^ω^=)", "hehe~"]
    _faceMinIndex := _faces.MinIndex()
    _faceMaxIndex := _faces.MaxIndex()
    Random, _faceIndex, _faceMinIndex, _faceMaxIndex
    _face := _faces[_faceIndex]
    return _face
}


FillLangName() {
    langs := DBLangFind()
    Gui, Gui:Default
    Gui, ListView, LangNameLV
    for index, lang in langs {
        LV_Add("", lang["id"], lang["name"])
    }
    SB_SetText("共计" langs.Length() "种语言", 2)
}
FillCodeName(langId, langName, sortStr) {
    codes := DBCodeFind(langId, sortStr)
    Gui, Gui:Default
    Gui, ListView, CodeNameLV
    LV_Delete()
    for index, code in codes {
        LV_Add("", code["id"], code["name"])
    }
    SB_SetText(langName "下共计" codes.Length() "种片段", 3)
}

;========================= 公共函数 =========================


;========================= DB-DAO =========================
DBLangFind() {
    return Query("select id, name from lang")
}
DBLangNew(langName) {
    resultSet := QueryOne("select ifnull(max(id) + 1, 1) as langId from lang")
    langId := resultSet["langId"]
    currentDB.Query("insert into lang (id, name) values (" langId ", '" langName "')" )
    return langId
}
DBLangDel(langId) {
    affectedRows := currentDB.Query("delete from lang where id = " langId)
}

DBLangCount(langName) {
    resultSet := QueryOne("select count(id) as count from lang where name = '" langName "'")
    return resultSet["count"]
}
DBCodeCount(langId) {
    resultSet := QueryOne("select count(id) as count from code where langId = " langId)
    return resultSet["count"]
}
DBCodeNew(codeObj) {
    resultSet := QueryOne("select ifnull(max(id) + 1, 1) as codeId from code")
    codeId := resultSet["codeId"]
    codeObj.id := codeId
    FormatTime, datetime, , yyyy-MM-dd HH:mm:ss
    codeObj.datetime := datetime
    currentDB.Insert(codeObj, "code")
    return codeId
}
DBCodeUpdate(codeObj) {
    flag := currentDB.Update(codeObj, "code")
    return flag
}
DBCodeFind(langId, sortStr:="") {
    sql := "select id, name, content from code where langId = " langId
    if (sortStr)
        sql := sql " order by " sortStr
    return Query(sql)
}
DBCodeDetail(codeId) {
    return QueryOne("select * from code where id = " codeId)
}
DBCodeDel(codeId) {
    affectedRows := currentDB.Query("delete from code where id = " codeId)
}
;========================= DB-DAO =========================


;========================= DB-Base =========================
DBConnect() {
	connectionString := A_ScriptDir "\contextCode.db"
	try {
		currentDB := DBA.DataBaseFactory.OpenDataBase("SQLite", connectionString)
	} catch e
		MsgBox,16, Error, % "Failed to create connection. Check your Connection string and DB Settings!`n`n" ExceptionDetail(e)
}
QueryOne(SQL){
    objs := Query(SQL)
    if (objs.Length())
        return objs[1]
}
Query(SQL){
	if (!IsObject(currentDB)) {
        MsgBox, 16, Error, No Connection avaiable. Please connect to a db first!
        return
	}
    SQL := Trim(SQL)
    if (!SQL)
        return
    try {
        resultSet := currentDB.OpenRecordSet(SQL)
        if (!is(resultSet, DBA.RecordSet))
            throw Exception("RecordSet Object expected! resultSet was of type: " typeof(resultSet), -1)
        return DBResultSet2Obj(resultSet)
    } catch e {
        MsgBox,16, Error, % "OpenRecordSet Failed.`n`n" ExceptionDetail(e) ;state := "!# " e.What " " e.Message
    }
}

DBResultSet2Obj(resultSet) {
    colNames := resultSet.getColumnNames()
    if (!colNames.Length())
        return Object()
    objs := Object()
    while(!resultSet.EOF){
        obj := Object()
        for index, colName in colNames {
            obj[colName] := resultSet[colName]
        }
        objs.Push(obj)
        resultSet.MoveNext()
    }
    return objs
}
;========================= DB-Base =========================