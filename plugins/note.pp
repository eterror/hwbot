library plugin_note;

uses
    dateutils,
    sysutils,
    strutils,
    hwTypes;

const
    plugin_name 		= 'note';
    plugin_command 		='.note';
    plugin_usage		=' [username] [message/command:clear]';
    plugin_author 		= 'solaris';
    plugin_version 		= '1.0';
    plugin_help:AnsiString 	= 'Shows messages sent to your nick (by the subsequent command: .note NICK [message]),like a inbox. Although as of now, only the latest message can be seen when using this command. If you are offline when a message is sent to your nick, the bot will automatically display it to you the next time you connect.';
    
    HW_BUF 	= 1024;
    HW_DB_FILE	= '/tmp/hwbot.plugin.note';
    
type
    TNote 	= record
	date:		TDateTime;
	from,
	nickname,
	message:	String;
    end;

var
    note:       array[1..HW_BUF] of TNote;


function noteGet(who: String) : TNote;
var
    i:  Integer;
    
begin
    for i:=1 to high(note) do
        if (note[i].nickname = who) then
        begin
            noteGet.message:=note[i].message;
            noteGet.from:=note[i].from;
            exit;
        end;
                                                                    
    noteGet.message:='';
    noteGet.from:='';
end;


function noteAdd(src, dst, msg: String) : Boolean;
var
    i:  Integer;
    
begin
    for i:=1 to high(note) do
        if (note[i].nickname = dst) then
        begin
            note[i].message:=msg;
            note[i].from:=src;
            note[i].date:=Now;
            exit;
        end;
                                                                             
    for i:=1 to high(note) do
	if (note[i].nickname = '') then
        begin
            note[i].from:=src;                                                                                                 
            note[i].nickname:=dst;                                                             
            note[i].message:=msg;
            note[i].date:=Now;
            exit;
        end;
                                                                                                                                                                     
    noteAdd:=FALSE;  
end;
                                                                                                         
                                                                            

function saveDB(): boolean;
var
    f:  file;
    
begin
    {$IFDEF DEBUG}writeln('[#] Dumping database.');{$ENDIF}
    assign(f, HW_DB_FILE);
    {$I-}rewrite(f, 1);{$I+}
                
    if (IOREsult <> 0) then
    begin
    {$IFDEF DEBUG}writeln('[#] Dumping database error (file access/no free space).');{$ENDIF}
        saveDB:=FALSE;
        exit;
    end;
                                                                        
    blockwrite(f, note, sizeof(note));
    close(f);
                                                                                            
    saveDB:=TRUE;
end;


function loadDB(): boolean;
var
    f:  file;
    
begin
    {$IFDEF DEBUG}writeln('[#] Loading database.');{$ENDIF}
    assign(f, HW_DB_FILE);
    {$I-}reset(f, 1);{$I+}
                
    if (IOREsult <> 0) then
    begin
    {$IFDEF DEBUG}writeln('[#] Dumping database error (file access/no free space).');{$ENDIF}
        loadDB:=FALSE;
        exit;
    end;
                                                                        
    blockread(f, note, sizeof(note));
    close(f);
                                                                                            
    loadDB:=TRUE;
end;
                                                                                                

function OnJoinLobby(const s: String):String; cdecl; export;
begin
    if (noteGet(s).message <> '') then
    begin
        OnJoinLobby:=s+': '+'Hello! '+noteGet(s).from+' sent note for you: '+noteGet(s).message;
        exit;
    end;     
    
    onJoinLobby:='';                                       
end;


function OnJoinRoom(const s: String):String; cdecl; export;
begin
    if (noteGet(s).message <> '') then
    begin
        OnJoinRoom:=s+': '+'Hello! '+noteGet(s).from+' sent note for you: '+noteGet(s).message;
        exit;
    end;     
    
    onJoinRoom:='';                                       
end;


function OnQuit(const s: String):String; cdecl; export;
begin
    onQuit:='';
end;

function PluginParse(const s: String; const u: array of TUser):String; cdecl; export;
var
    nick:	String;
    param:	String;
    msg:	String;
    
    
begin
    nick:=copy(s, 1, pos(':', s)-1);
        
    if (pos(#32, s) = 0) then
    	param:='' 
    else
    begin
        param:=copy(s, pos(#32, s)+1, length(s));
        param:=TrimLeft(param);
        param:=TrimRight(param);
    end;
        
    if (copy(nick ,1, 5) = 'Guest') then
        begin
            PluginParse:='You need to be registered user.';
    	    exit;
        end;
    
    if (param = '') then
    begin        
	if (copy(nick, 1, 5) = 'Guest') then
	begin
	    PluginParse:='You need to be registered user.';
	    exit;
	end;
	
	if (noteGet(nick).message <> '') then
    	    PluginParse:=nick+': New note from '+noteGet(nick).from+': '+noteGet(nick).message 
    	else
    	    PluginParse:=nick+': No note for you.';
    end else
    begin
	PluginParse:='';
	
        if (ExtractWord(1, param, [#32]) = 'clear') or (ExtractWord(1, param, [#32]) = 'del') then
        begin
    	    noteAdd('', nick, '');
    	    PluginParse:=nick+': Note deleted.';
    	end else
    	begin
    	    msg:=copy(param, pos(#32, param)+1, length(param));
    	    noteAdd(nick, ExtractWord(1, param, [#32]), msg); 
    	    
    	    PluginParse:=nick+': Note sent';
    	    writeln('NOTA DLA ',ExtractWord(1, param, [#32]),' OD ',nick,' TRESC: ',msg);
    	end;
                                                                    
        saveDB();
    end;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
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
    GetPluginHelp,
    GetPluginUsage;
                                    
                                    
begin
    loadDB();
end.
                                                    