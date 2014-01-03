library plugin_memo;


uses
    sysutils,
    strutils,
    hwTypes;
    

const
    plugin_name = 'memo';
    plugin_command ='.memo';
    plugin_help = 'Memo is a lite message system.';
    plugin_author = 'solaris';
    plugin_version = '1.0';
    plugin_usage = '[username/command:mark|del|unmark] [message]';
    
    INBOX_SIZE	= 5;
    HW_BUF	= 1024;
    HW_DB	= '/tmp/hwbot.plugin.memo';
    
    M_READ = 0;
    M_UNREAD = 1;
    M_MARKED = 2;


type
    TMemo = packed record
        nickname:       String[64];
        cnt:            Byte;
        messages:       array[1..INBOX_SIZE] of record
                                            date:   TDateTime;
                                            id:     Byte;
                                            from:   String[64];
                                            text:   String;
                                            state:  Byte;
                                       end;
    end;


var
    memo:       array[1..HW_BUF] of TMemo;


function saveDB(): boolean;
var
    f:  file;

begin
    assign(f, HW_DB);
    {$I-}rewrite(f, 1);{$I+}

    if (IOREsult <> 0) then
        begin
            saveDB:=FALSE;
            exit;
        end;

    blockwrite(f, memo, sizeof(memo));
    close(f);

    saveDB:=TRUE;
end;


function loadDB(): boolean;
var
    f:  file;

begin
    assign(f, HW_DB);
    {$I-}reset(f, 1); {$I+}

    if (IOREsult <> 0) then
    begin
	//saveDB();
	loadDB:=FALSE;
        exit;
    end;

    blockread(f, memo, sizeof(memo));
    close(f);

    loadDB:=TRUE;
end;


function isnewMemo(src: String): boolean;
var
    i, j:       Integer;

begin
    isnewMemo:=FALSE;

    for i:=1 to high(memo) do
        if (memo[i].nickname = src) then
            begin
                for j:=1 to INBOX_SIZE do
                    if (memo[i].messages[j].state = M_UNREAD) then
                    begin
                        isnewMemo:=TRUE;
                        //break;
                        exit;
                    end;
            end;
end;


function setMark(src: String; id, _mark: Byte) : boolean;
var
    i:  Integer;
begin
    // Existing user
    for i:=1 to high(memo) do
        if (memo[i].nickname = src) then
            begin
                memo[i].messages[id].state:=_mark;
                setMark:=TRUE;
                break;
            end;

    setMark:=FALSE;
end;


function delMemo(src: String; id: Byte) : boolean;
var
    i, j:       Integer;
begin
    // Existing user
    for i:=1 to high(memo) do
        if (memo[i].nickname = src) then
        begin
            if (id = 255){*} then
            begin
                for j:=1 to INBOX_SIZE do
                begin
                    if (memo[i].messages[j].state =2) then
                        continue;

                    memo[i].messages[j].text:='';
                    memo[i].messages[j].date:=0;
                    memo[i].messages[j].from:='';
                    memo[i].messages[j].state:=M_READ;
                    memo[i].cnt:=1;
                end;

                break;
            end else
            begin
                if (memo[i].messages[id].state = 2) then
                    break;

                memo[i].messages[id].text:='';
                memo[i].messages[id].date:=0;
                memo[i].messages[id].from:='';
                memo[i].messages[id].state:=M_READ;
                break;
            end;
        end;

    delMemo:=TRUE;
end;


function sendMemo(from, src, txt: String): Boolean;
var
    i, c:       Integer;

begin
    // Existing user
    for i:=1 to high(memo) do
        if (memo[i].nickname = src) then
        begin

            if (memo[i].cnt > INBOX_SIZE) then
                memo[i].cnt:=1;

            c:=memo[i].cnt;

            memo[i].messages[c].text:=txt;
            memo[i].messages[c].date:=Now;
            memo[i].messages[c].from:=from;
            memo[i].messages[c].state:=M_UNREAD;
            memo[i].messages[c].id:=c;
            memo[i].cnt+=1;
            sendMemo:=TRUE;
            exit;
        end;

    // New user
    for i:=1 to high(memo) do
    begin
        if (memo[i].nickname = '') then
        begin
            memo[i].cnt:=1;
            memo[i].nickname:=src;
            memo[i].messages[1].text:=txt;
            memo[i].messages[1].date:=Now;
            memo[i].messages[1].from:=from;
            memo[i].messages[1].state:=M_UNREAD;
            memo[i].messages[1].id:=1;
            memo[i].cnt+=1;
            sendMemo:=TRUE;
            exit;
        end;
    end;

    sendMemo:=FALSE;
end;


function showMemo(src: String):String;
var
    i, j:	 	Integer;
    rchar:      	Char;
    c2:         	Byte;
    out:		AnsiString;

begin
    ShowMemo:='';
    out:='';
    c2:=0;

    for i:=1 to high(memo) do
        if (memo[i].nickname = src) then
        begin
            for j:=1 to high(memo[i].messages) do
            begin
                case (memo[i].messages[j].state) of
                    M_UNREAD: rchar:='#';
                    M_READ:   rchar:=' ';
                    M_MARKED: rchar:='*';
                end;

                if (memo[i].messages[j].text = '') and (memo[i].messages[j].from = '') then
                begin
                    c2+=1;
                    continue;
                end;

                if (memo[i].messages[j].state <> M_MARKED) then
                    memo[i].messages[j].state:=M_READ;

                out+=src+': ('+IntToStr(j)+') ['+rchar+'] '+DateToStr(memo[i].messages[j].date)+' <'+memo[i].messages[j].from+'>'+#32+memo[i].messages[j].text+#10;
        	out+=#10+'CHAT'+#10;
            end;
        
            if (ShowMemo <> '') then
        	exit;

            if (c2 >= 5) then
            begin
        	ShowMemo:='';
            end else
            begin
                out+=#10;            
    		ShowMemo:=out;
            end;

            exit;
        end;
end;


function OnJoinRoom(const s: String):String; cdecl; export;
begin
    if (isNewMemo(s)) then
	OnJoinRoom:=s+': You have unread messages. Type .memo' 
    else
	OnJoinRoom:='';
end;


function OnJoinLobby(const s: String):String; cdecl; export;
begin
    if (isNewMemo(s)) then
	OnJoinLobby:=s+': You have unread messages. Type .memo'
    else
	OnJoinLobby:='';
end;


function OnQuit(const s: String):String; cdecl; export;
begin
    onQuit:='';
end;


function PluginParse(const s: String; const u: array of TUser):String; cdecl; export;
var
    nick:	String;
    param:	String;
    b:		String;
    msg:	String;
    
begin
    nick:=copy(s, 1, pos(':', s)-1);
    
    if (pos(#32, s) <> 0) then
	param:=copy(s, pos(#32,s)+1, length(s)) else
	param:='';
    
    if (copy(nick,1, 5) = 'Guest') then
    begin
    	PluginParse:=nick+': You need have registered nickname.';
            exit;
    end;
    
    if (length(param) = 0) then
    begin
	b:=ShowMemo(nick);
	
	if (length(b) = 0) then
	    PluginParse:=nick+': No messages.' 
	else
	    begin
		PluginParse:=b;
		saveDB();
		exit;
	    end;
	exit;
    end;

    if (ExtractWord(1, param, [#32]) = 'del') then
    begin
	b:=ExtractWord(2, param, [#32]);
	
	if (b[1] in ['1'..'9']) and (length(b) = 1) then
        begin
            if delMemo(nick, StrToInt(b)) then
            begin
        	PluginParse:=nick+': Message deleted.';
            end;
        end else
            if (b = '*') then
            begin
                if delMemo(nick, 255) then
                begin
                    PluginParse:=nick+': All messages deleted.';
                end;
            end;
            
        saveDB();
        exit;
    end;
    
    
    if (ExtractWord(1, param, [#32]) = 'mark') then
    begin
	b:=ExtractWord(2, param, [#32]);
	                
	if (b[1] in ['1'..'9']) and (length(b) = 1) then
        begin
            setMark(nick, StrToInt(b), 2);
            PluginParse:=nick+': Message marked.';
	end;
	
	saveDB();
	exit;
    end;
    
    if (ExtractWord(1, param, [#32]) = 'unmark') then
    begin
	b:=ExtractWord(2, param, [#32]);
	
	if (b[1] in ['1'..'9']) and (length(b) = 1) then
        begin
            setMark(nick, StrToInt(b), 2);
            PluginParse:=nick+': Message unmarked.';
	end;
	
	saveDB();
	exit;
    end;

    if (pos(#32, param) <> 0) then
	msg:=Copy(param, pos(#32, param)+1, length(param))
    else
	msg:='';
	
    if (msg = '') then
    begin
	PluginParse:=nick+': You need to enter message for you recipient.';
	exit;
    end;
    
    // HW_NICK
    if ExtractWord(1, param, [#32]) = 'INFOBOT' then
    begin
	PluginParse:=nick+': No way!';
	exit;
    end;

    sendMemo(nick, ExtractWord(1, param, [#32]), msg);
    PluginParse:=nick+': Memo sent.';
    saveDB();
end;   
 

function GetPluginCommand:String; cdecl; export;
begin
    GetPluginCommand:=plugin_command;
end;

    
function GetPluginVersion:String; cdecl; export;
begin
    GetPluginVersion:=plugin_version;
end;

        
function GetPluginAuthor:String; cdecl; export;
begin
    GetPluginAuthor:=plugin_author;
end;
    
            
function GetPluginName:String; cdecl; export;
begin
    GetPluginName:=plugin_name;
end;


function GetPluginUsage:String; cdecl; export;
begin
    GetPluginUsage:=plugin_usage;
end;


function GetPluginHelp:AnsiString; cdecl; export;
begin
    GetPluginHelp:=plugin_help;
end;
                

exports
    OnJoinLobby,
    OnJoinRoom,
    OnQuit,
    PluginParse,
    GetPluginCommand,
    GetPluginName,
    GetPluginVersion,
    GetPluginAuthor,
    GetPluginUsage,
    GetPluginHelp;
                                    
                                    
begin
    loadDB();
end.
                                                    
