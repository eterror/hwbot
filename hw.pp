(*
 * InfoBOT, lobby commander (a bot a for Hedgewars lobby chat)
 * Copyright (c) 2013 Solaris <solargrim@gmail.com>
*)

{$UNDEF DEBUG}
{$MODE OBJFPC}


{
TODO:
 - better support for NOTICE and ERROR
 - better support for USER FLAGS (plugin command: onFlagChange)
 - sometimes bot use 100% of cpu (?)
}

program Hedgewars_InfoBOT(lobby, commander);

uses
    linux,
    sockets,
    errors,
    sysutils,
    dateutils,
    geoip,
    baseunix,
    dynlibs,
    strutils,
    hwTypes;
 
var 
    user:	array of hwTypes.TUser; 
    plugin:	array of hwTypes.TPlugin;
    pc:		Byte;
    

function hwReconnect():boolean;forward;
function hwDisconnect():boolean;forward;
function hwConnect():boolean;forward;
function hwLoop():boolean;forward;
function hwRegister():boolean;forward;
function hwInfo():boolean;forward;
function hwLoadPlugin(name:string):byte;forward;
function hwUnloadPlugin(id: Integer):Boolean;forward;
function hwReloadPlugin(id: byte; name:string):byte;forward;
function hwLoadConfig():Boolean;forward;
procedure hwInitPLugins(); forward;


function uAddFlag(name: String; flag: string):boolean;
var
    i:	Integer;
    
begin
    for i:=0 to (high(user)) do
	if (user[i].nickname = name) then 
        begin
    	    user[i].mode:=flag;
    	    exit(TRUE);
        end; 
     
    exit(FALSE);
end;


function uAddUser(name: String; flag: String):boolean;
var
    i:	Integer;
    
begin
    for i:=0 to high(user) do
	if (user[i].nickname = '') then 
	begin
    	    user[i].upname:=AnsiUpperCase(name);
	    user[i].mode:=flag;
    	    user[i].nickname:=name;
    	    exit(TRUE);
        end;
     
    exit(FALSE);
end;


function uDelUser(name: String):boolean;
var
    i:	Integer;
    
begin
    for i:=0 to high(user) do
	if (user[i].upname = AnsiUpperCase(name)) then 
	begin
    	    user[i].nickname:='';
	    user[i].upname:='';
    	    user[i].mode:='';
    	    exit(TRUE);
        end;
    
    exit(FALSE);
end;

    
function Parse(input: String) : boolean;
    
    function StripHTML(S: ansistring): string;
    var
	TagBegin, TagEnd, TagLength: integer;
  
    begin
	TagBegin:=Pos('<', S);    
    
        while (TagBegin > 0) do 
        begin 
            TagEnd:=Pos('>', S);              
    	    TagLength:=TagEnd - TagBegin + 1;
            Delete(S, TagBegin, TagLength);    
            TagBegin:=Pos('<', S);            
        end;      
                    
	StripHTML:=S;                  
    end;    


var
    s1, s2, s3, s4, s5, s6, s7,s8: String;  
    output: AnsiString;
    i, k: integer;  
    
begin
// DEFAULT SERVER COMMANDS
    if (input = 'BYE') then
    begin
	readln(sin, s1);
	writeln('[!] Register error: ',s1);
	quit:=TRUE;
	exit;
    end;
    
    
    if (input = 'ERROR') then
    begin
	readln(sin, s1);
	writeln('[!] Error: ',s1);
	
	if (pos('Incorrect',s1) = 0) then
	    hwReconnect();
	
	exit;
    end;
    
    
    if (input = 'NOTICE') then
    begin
	// hwReconnect(); {?}
	exit;
    end;
    
    
    if (input = 'QUIT') then 
    begin
	writeln('[#] Closing. ');
	exit;
    end;
 
 
    if (input = 'PING') then 
    begin
	writeln(sOut, 'PONG',#10);
	exit;
    end;
 
 
    if (input = 'SERVER_MESSAGE') then 
    begin
	readln(sIn, motd);
	writeln('[#] MESSAGE OF THE DAY');
	writeln(StripHTML(motd));
	exit;
    end;
 
 
    if (input = 'LOBBY:LEFT') then 
    begin
	readln(sIn, s1);
	readln(sIn, s2);
    
	writeln('[#] ',s1,' quits (',s2,')');
	
	uDelUser(s1);
	
	// plugin:OnQuit (like PartLobby)
	if (pc <> 0) then    
	for k:=1 to (pc) do
	    begin
		try
		    s8:=plugin[k].onQuit(s1);
		    
		    if (length(s8) = 0) then
			continue;
			
		    writeln(sout, 'CHAT'+#10+s8, #10);
		except
		    continue;
		end;
	    end;
    
	if (s1 = HW_NICK) then
	begin
	    hwReconnect();
	    exit;
	end;
    end;
 
 
    if (input = 'JOINED') then 
    begin
	readln(sIn, s1);
	writeln('[#] ',s1,' joined to room.');
	
	// plugin:OnRoomJoin
	if (pc <> 0) then    
	for k:=1 to (pc) do
	    begin
		try
		    s8:=plugin[k].onJoinRoom(s1);
		    
		    if (length(s8) = 0) then
			continue;
		    
		    writeln(sout, 'CHAT'+#10,s8,#10);
		except
		    continue;
		end;
	    end;
    
	exit;
    end;
    
 
     if (input = 'LOBBY:JOINED') then 
     begin
	readln(sIn, s1);
	writeln('[#] ',s1,' connected.');
	
	// plugin:OnLobbyJoin
	if (pc <> 0) then    
	for k:=1 to (pc) do
	begin
	    try
		s8:=plugin[k].OnJoinLobby(s1);
		    
		if (length(s8) = 0) then
		    continue;
			
		writeln(sout, 'CHAT'+#10,s8, #10);
	    except
		continue;
	    end;
	end;
    
	uAddUser(s1, '+u');
	exit;
     end;
 
 
    if (input = 'CLIENT_FLAGS') then 
    begin
	readln(sin, s1);
	readln(sin, s2);
	writeln('[#] ',s2,': new user flag: ',s1);
	uAddFlag(s2, s1);
    
	if (s1 = '-i') then 
	begin
	    {plugin:onBackLobby}
	end;
    end;
    
    
    if (input = 'ROOM') then 
    begin
	readln(sin, s1);
    
	if (s1 = 'ADD') then 
	begin
	    readln(sin, s1);
	    readln(sin, s2);
	    readln(sin, s3);
	    readln(sin, s4);
	    readln(sin, s5);
	    readln(sin, s6);
	    readln(sin, s7);
	    readln(sin, s8);
	    readln(sin, s8);
	
	    writeln('[#] New room: ',s2);	
	    writeln(sout, 'CHAT'+#10,'/me -> ',s5,' created new room: ',s2,#10);
	end;
	
	
	if (s1 = 'DEL') then
	begin
	    readln(sin, s1);
	    writeln('[#] Room deleted: ',s1);
	end;
    
    
	if (s1 = 'UPD') then
	begin
	    readln(sin, s1);
	    readln(sin, s2);
	    readln(sin, s3);
	    readln(sin, s4);
	    readln(sin, s5);
	    readln(sin, s6);
	    readln(sin, s7);
	    readln(sin, s8);
	    readln(sin, s8);
	
	    writeln('[#] Update room: ',s1{s3});
	end;
    end;

 
    if (input = 'CHAT') then 
    begin
	readln(sin, s1);
	readln(sin, s2);
    
	writeln('[#] [',TimeToStr(Now),'] ',s1,': ',s2);
  
	// Private bot commands
	if (copy(s2, 1, 5) = '.help') then
	begin
	    s3:=copy(s2, 7, length(s2));
	    s3:=trim(s3);
	    
	    // Custom help for plugins
	    if (pc <> 0) and (s3 <> '') then    
	    begin
		for k:=1 to (pc) do
		    if (s3 = trim(plugin[k].name)) then
		    begin
			try 
			    writeln(sout, 'CHAT'+#10+'HELP ('+s3+'): '+plugin[k].ghelp(), #10);
			    exit;
			except
			    writeln(sout, 'CHAT'+#10+s1+': Help text is not defined.'+#10);
			    exit;
			end;
	    
			exit;
		    end;
		    
		writeln(sout, 'CHAT'+#10+s1+': Help is not available.'+#10);
		exit;
	    end;
	    
	
	    writeln(sOut, 'CHAT');writeln(sout, 'Available public commands:',#10);
	    writeln(sout, 'CHAT');writeln(sout, ' .help [command]',#10);
	    writeln(sOut, 'CHAT');writeln(sout, ' .version',#10);
	    
	    // plugin:usage
	    if (pc <> 0) then    
	    for k:=1 to (pc) do
	    begin
		try
		    writeln(sout, 'CHAT'+#10+plugin[k].cmd+#32+plugin[k].usage+' (Plugin)'+ #10);
		except
		    continue;
		end;
	    end;
	end;
    
    
	if (copy(s2, 1, length(HW_NICK)) = HW_NICK) then
	begin
	    writeln(sout, 'CHAT');
	    
	    case (random(2)) of
		0: writeln(sout, s1, ': need help? Type .help for more information',#10);
		1: writeln(sout, s1, ': Im hedgewarsbot! Type .help if you want see more information',#10);
	    end;
	end;
    
    
        if (s2 = '.version') then 
	begin
	    writeln(sout, 'CHAT'+#10+'InfoBOT (hedgewars lobby commander) by solargrim@gmail.com, version: '+VERSION{$IFDEF DEBUG}+'-DEBUG'{$ENDIF},#10);
	    exit;
	end;
	
	
	if (ExtractWord(1, s2, [#32]) = '.join') and (s1 = HW_ADMIN) then
	begin
	    s3:=ExtractWord(2, s2, [#32]);
	    
	    if (s3 <> '') then
	    begin
		writeln(sout, 'CREATE_ROOM');
		writeln(sout, s3,#10);
		writeln(sout, 'JOIN_ROOM');
		writeln(sout, s3,#10);
	    end else
	    begin
		writeln(sout, 'CREATE_ROOM');
		writeln(sout, HW_ROOM,#10);
		writeln(sout, 'JOIN_ROOM');
		writeln(sout, HW_ROOM,#10);
	    end;
	    
	    exit;
	end;
	
	
	if (copy(s2, 1, 4) = '.raw') and (s1 = HW_ADMIN) then
	begin
	    s3:=copy(s2, 6, length(s2));
	    writeln('[*] Sending RAW DATA to server: ',s3);
	    
	    s4:=StringReplace(s3, '\n', #10, [rfReplaceAll]);
	    
	    if (s4[length(s4)] <> #10) then
		s4+=#10;
	    
	    if (s4 <> '') then
		writeln(sout, s4);
	end;
	
	
	if (copy(s2, 1, 5) = '.kick') and (s1 = HW_ADMIN) then
	begin
	    s3:=ExtractWord(2, s2, [#32]);
	    
	    if (s3 = HW_ADMIN) then
		exit;
	    
	    writeln('[*] Kicking user from room: ',s3);
	    writeln(sout, 'KICK',#10,s3,#10);
	    exit;
	end;
	
	
	if (s2 = '.op') and (s1 = HW_ADMIN) then
	begin
	    writeln('[*] Adding room operator status to bot admin');
	    writeln(sout, 'CMD');
	    writeln(sout, 'delegate ',HW_ADMIN,#10);
	    exit;
	end;
	
	
	if (s2 = '.part') and (s1 = HW_ADMIN) then
	begin
	    writeln(sout, 'PART',#10);
	    exit;
	end;
	
	
	if (s2 = '.die') then 
	begin
	    if (s1 = HW_ADMIN) then 
		quit:=True 
	    else
	    begin
		writeln(sout,'CHAT');
		
		if (random(2) = 1) then
		    writeln(sout, 'No way ',s1,'!',#10) else
		    writeln(sout, 'Try again later ',s1,'!',#10);
	    end;
	end;
 
 
	if (s2 = '.fork') and (s1 = HW_ADMIN) then
	begin
	    fpfork();
	end;
	
    
	if (copy(s2, 1,4)= '.say') and (s1 = HW_ADMIN) then 
	begin
	    if (s2='.say') or (s2='.say ') then
		exit;
	
	    writeln(sout, 'CHAT');
	    writeln(sout, trim(copy(s2, 5, length(s2)))+#10);
	end;
    
    
	if (s2 = '.users') then 
	begin
	    writeln('USER LIST ->');
	
	    for i:=0 to high(user) do 
		if (user[i].nickname <> '') then
		    write(user[i].nickname + '(',user[i].mode,') ');
	end;
    
 
	if (copy(s2, 1, 7) = '.plugin') and (s1 = HW_ADMIN) then
	begin
	    if (ExtractWord(2, s2, [#32]) = 'list') then
	    begin
	    	if (pc = 0) then
		begin
		    writeln(sout, 'CHAT',#10,s1,': No plugins loaded.',#10);
		exit;
		end;
	    
		for k:=1 to (pc) do
		begin
		    try
			writeln(sout, 'CHAT'+#10+s1,': ',k,'. ',plugin[k].name,' -> ',plugin[k].author,' (',plugin[k].fname,'):',plugin[k].ver,' (',plugin[k].cmd,')'#10);
		    except
			continue;
		    end;
		end;
	    end;
	    
	    
	    if (ExtractWord(2, s2, [#32]) = 'reload') then
	    begin
		s8:=ExtractWord(3, s2, [#32]);
		
		writeln('[P:Reloading]: ',s8);
		
		try
		    i:=StrToInt(ExtractWord(3, s2, [#32]));
		except
		    writeln('FAILED!');
		    exit;
		end;
		
		try
		    UnLoadLibrary(plugin[i].hnd);
		except
		    writeln('FAILED!');
		    exit;
		end;
		
		if (hwReloadPlugin(i, plugin[i].fname) = 0) then
		    writeln(sout,'CHAT'+#10+s1+': Plugin '+plugin[i].name+' reloaded.',#10) else
		    writeln(sout,'CHAT'+#10+s1+': Failed to reload plugin.',#10);
		exit;
	    end;
	    
	    if (ExtractWord(2, s2, [#32]) = 'load') then
	    begin
		writeln(sout, 'CHAT');
		
		s3:=HW_PLUGINS+ExtractWord(3, s2,[#32])+'.so';
		
		case hwLoadPlugin(s3) of
		    0: writeln(sout, s1,': Plugin loaded: ',s3,#10);
		    1: writeln(sout, s1,': Plugin error (not exists).',#10);
		    2: writeln(sout, s1,': Plugin do not exists (wrong patch?).',#10);
		    3: writeln(sout, s1,': Plugin already loaded.',#10);
		    4: writeln(sout, s1,': Plugin deprecated.',#10);
		end;

		exit;
	    end;
	    
	    if (ExtractWord(2, s2, [#32]) = 'unload') then
	    begin
		try
		    k:=StrToInt(ExtractWord(3, s2, [#32]));    
		except
		    exit;
		end;
		
		if (hwUnloadPlugin(k)) then
		    writeln(sout, 'CHAT',#10,s1,': Plugin removed.',#10)
		else
		    writeln(sout, 'CHAT',#10,s1,': Error while removing plugin.',#10);
	    end;
	end;
	
	
	// run plugins by defined command
	if (pc <> 0) then    
	    for k:=1 to (pc) do
		if (copy(s2, 1, pos(#32, s2)-1) = plugin[k].cmd) or (plugin[k].cmd = s2) then
		begin
		    try 
			output:=plugin[k].Parse(s1+':'+s2, user, HW_NICK);
			
			if (length(output) <> 0) then
			    writeln(sout, 'CHAT'+#10,output, #10);
		    except
			continue;
		    end;
	    
		exit;
	    end;
 
    end; // .private commands
 
 exit(TRUE);
end;


function hwReconnect():boolean;
begin
    writeln('[#] Reconnecting (15s)...');
    hwDisconnect();
    sleep(15000);
    hwConnect();
    hwRegister();
    exit(TRUE);
end;


function hwConnect():boolean;
begin
    writeln('[#] Estabilising connection to HW server');
    randomize;
    
    sAddr.sin_family:=AF_INET;
    sAddr.sin_Port:=htons(HW_PORT);
    sAddr.sin_Addr.s_addr:=LongInt((StrToNetAddr(HW_IP)));
    
    S:=fpSocket(AF_INET, SOCK_STREAM, 0);
    
    // deprecated function, need fpConnect()
    if not sockets.Connect(S, sAddr, sIn, sOut) then 
    begin
	writeln(' error# ', strerror(SocketError));
	hwConnect:=FALSE;
	exit;
    end;
    
    Reset(sIn);
    Rewrite(sOut);
    
    hwConnect:=TRUE;
end;


function hwReLoadPlugin(id: Byte; name: String):Byte;
begin
    try
	plugin[id].hnd:=LoadLibrary(name);
    except
	exit(1);
    end;
    
    Pointer(plugin[id].parse):=GetProcedureAddress(plugin[id].hnd, 'PluginParse');
    Pointer(plugin[id].onquit):=GetProcedureAddress(plugin[id].hnd, 'OnQuit');
    Pointer(plugin[id].onjoinlobby):=GetProcedureAddress(plugin[id].hnd, 'OnJoinLobby');
    Pointer(plugin[id].onjoinroom):=GetProcedureAddress(plugin[id].hnd, 'OnJoinRoom');
    Pointer(plugin[id].gcmd):=GetProcedureAddress(plugin[id].hnd, 'GetPluginCommand');
    Pointer(plugin[id].gver):=GetProcedureAddress(plugin[id].hnd, 'GetPluginVersion');
    Pointer(plugin[id].gauthor):=GetProcedureAddress(plugin[id].hnd, 'GetPluginAuthor');
    Pointer(plugin[id].gname):=GetProcedureAddress(plugin[id].hnd, 'GetPluginName');
    Pointer(plugin[id].ghelp):=GetProcedureAddress(plugin[id].hnd, 'GetPluginHelp');
    Pointer(plugin[id].gusage):=GetProcedureAddress(plugin[id].hnd, 'GetPluginUsage');
    
    plugin[id].cmd:=plugin[id].gcmd();
    plugin[id].ver:=plugin[id].gver();
    plugin[id].author:=plugin[id].gauthor();
    plugin[id].name:=plugin[id].gname();
    plugin[id].usage:=plugin[id].gusage();
    plugin[id].help:=plugin[id].ghelp();
    plugin[id].fname:=name;
    
    hwReloadPlugin:=0;
end;


function hwLoadPlugin(name: String):Byte;
var
    i:	Integer;
    
begin
    pc+=1;
    plugin[pc]:=TPlugin.Create;
    
    write('[P:',pc,'] ',name,': ');
    
    for i:=1 to (pc-1) do
	if (plugin[i].fname = name) then
	begin
	    plugin[pc].Free;
	    pc-=1;
	    writeln('FAILED');
	    exit(3);
	end;
    
    if (not FileExists(name)) then
    begin
	plugin[pc].Free;
	pc-=1;
	writeln('FAILED');
	exit(2);
    end;
    
    try
	plugin[pc].hnd:=LoadLibrary(name);
    except
	{...}
    end;
    
    if (plugin[pc].hnd = 0) then
    begin
	plugin[pc].Free;
	writeln('FAILED') ;
	plugin[pc].cmd:='';
	pc-=1;
	exit(1);
    end else
	writeln('OK ');
    
    Pointer(plugin[pc].parse):=GetProcedureAddress(plugin[pc].hnd, 'PluginParse');
    Pointer(plugin[pc].onquit):=GetProcedureAddress(plugin[pc].hnd, 'OnQuit');
    Pointer(plugin[pc].onjoinroom):=GetProcedureAddress(plugin[pc].hnd, 'OnJoinRoom');
    Pointer(plugin[pc].onjoinlobby):=GetProcedureAddress(plugin[pc].hnd, 'OnJoinLobby');
    Pointer(plugin[pc].gcmd):=GetProcedureAddress(plugin[pc].hnd, 'GetPluginCommand');
    Pointer(plugin[pc].gver):=GetProcedureAddress(plugin[pc].hnd, 'GetPluginVersion');
    Pointer(plugin[pc].gauthor):=GetProcedureAddress(plugin[pc].hnd, 'GetPluginAuthor');
    Pointer(plugin[pc].gname):=GetProcedureAddress(plugin[pc].hnd, 'GetPluginName');
    Pointer(plugin[pc].ghelp):=GetProcedureAddress(plugin[pc].hnd, 'GetPluginHelp');
    Pointer(plugin[pc].gusage):=GetProcedureAddress(plugin[pc].hnd, 'GetPluginUsage');
    
    try
	Pointer(plugin[pc].init):=GetProcedureAddress(plugin[pc].hnd, 'PluginInit');
    except
    end;


    if  (Pointer(plugin[pc].parse) = nil) or
	(Pointer(plugin[pc].onquit) = nil) or
	(Pointer(plugin[pc].onjoinlobby) = nil) or
	(Pointer(plugin[pc].onjoinroom) = nil) or
	(Pointer(plugin[pc].gcmd) = nil) or
	(Pointer(plugin[pc].gver) = nil) or
	(Pointer(plugin[pc].gauthor) = nil) or
	(Pointer(plugin[pc].ghelp) = nil) or
	(Pointer(plugin[pc].gusage) = nil) or
	(Pointer(plugin[pc].gname) = nil) then
    begin
	writeln('[!] Not defined all functions in plugin. Case sensivity may cause this errors.');
	pc-=1;
	exit(4);
    end;
	
    plugin[pc].cmd:=plugin[pc].gcmd();
    plugin[pc].ver:=plugin[pc].gver();
    plugin[pc].author:=plugin[pc].gauthor();
    plugin[pc].name:=plugin[pc].gname();
    plugin[pc].usage:=plugin[pc].gusage();
    plugin[pc].help:=plugin[pc].ghelp();
    plugin[pc].fname:=name;
    
    writeln('[P:',pc,':NAME]: ',plugin[pc].name,' / ',plugin[pc].author,' ',plugin[pc].ver,' -> ',plugin[pc].cmd);    
    
    hwLoadPlugin:=0;
end;


function hwUnloadPlugin(id: Integer):boolean;
begin
    write('[*] Removing plugin -> ',id,': ');
    try
	UnloadLibrary(plugin[i].hnd);
	plugin[i].Free;
	writeln('OK');
	exit(TRUE)
    except
	writeln('FAIL');
	exit(FALSE)
    end;
end;


procedure hwInitPlugins();
var
    i:	Integer;
    
begin
    for i:=0 to (pc) do
	try
	    plugin[i].Init(sin, sout);
	except
	    continue;
	end;
end;


function hwRegister():boolean;
var
    k:		Integer;
    buf:	String;
    
begin
    writeln('[#] Registering user');
        
        
    writeln(sOut, 'PROTO');
    writeln(sOut, HW_PROTO,#10);
    writeln(sOut, 'NICK');
    writeln(sOut, HW_NICK,#10);
    
    // SKIP FIRST DATA
    for i:=1 to 12 do 
    begin
	readln(sin, buf);
	{$IFDEF DEBUG}writeln('[DEBUG]',buf,'[!]');{$ENDIF}
	
	if (buf = 'ASKPASSWORD') and (HW_PASSWORD <> '') then
	begin
	    writeln('[*] Sending password (',HW_PASSWORD,')');
	    writeln(sout, 'PASSWORD');
	    writeln(sout, HW_PASSWORD,#10);
	end;
	
	if (buf = 'NOTICE') then
	begin
	    readln(sin, buf);
	    writeln('[%] Server notice: ',buf);
	    
	    HW_NICK+=IntToStr(random(10));
	    
	    hwReconnect();
	end;
	
	if (buf = 'ERROR') or (buf = 'BYE') then
	begin
	    readln(sin, buf);
	    
	    writeln('[!] Connection error: ',buf);
	    
	    if (buf = 'Authentication failed') then
	    begin
		quit:=TRUE;
		exit;
	    end;
	    
	    hwReconnect();
	end;
    end;
        
    write('[#] Users online: ');
    i:=0;
    repeat
	readln(sin, line);
	if (line = '') then break;
	i+=1;
	//write(line,',');
	uAddUser(line, '+u');
    until (line = '');
    
    writeln(i);
        
    hwRegister:=TRUE;
    
    if (length(HW_ROOM) <> 0) then
    begin
	writeln('[#] Joining to room');
	writeln(sout, 'CREATE_ROOM');
	writeln(sout, HW_ROOM,#10);
	writeln(sout, 'JOIN_ROOM');
	writeln(sout, HW_ROOM,#10);
	writeln(sout, 'TOGGLE_READY');
	writeln(sout);
    
	writeln(sout, 'ADD_TEAM');
	writeln(sout, 'Welcome to Hedgewars INFOBOT Service by Terror');
	
	for i:=1 to 22 do
	    writeln(sout, chr(65+random(15)));	
	
	writeln(sout);   
    
	writeln(sout, 'ADD_TEAM');
	writeln(sout, 'Type .help for command list');
	
	for i:=1 to 22 do
	    writeln(sout, chr(65+random(15)));
	    	
	writeln(sout);                                                                                               
    end;                                                                                                            
end;


function hwDisconnect():boolean;
begin
    writeln(sout, 'QUIT');
    writeln(sout, 'I will be back!',#10);
    close(sOut);
    exit(TRUE);
end;


function hwLoop():boolean;
begin
    repeat
	readln(sIn, line);
	{$IFDEF DEBUG}if line<>'' then writeln(' -> "',line,'"');{$ENDIF}
	Parse(line);
    until (quit);
    
    hwLoop:=TRUE;
end;


function hwInfo():boolean;
var
    r:	String;
    
begin
    hwInfo:=TRUE;
    
    if (length(HW_ROOM) = 0) then
	r:='Lobby' 
    else
	r:=HW_ROOM;
    
    writeln(Format('[*] Nickname: %s', [HW_NICK]));
    writeln(Format('[*] Protocol: %d ',[HW_PROTO]));
    writeln(Format('[*] Server: %s:%d',[HW_IP, HW_PORT]));
    writeln(Format('[*] Config file: %s', [HW_CONFIG]));
    writeln(Format('[*] Plugins patch: %s', [HW_PLUGINS]));
    writeln(Format('[*] Room: %s', [r]));
    // other options...
end;


function hwLoadConfig():boolean;
var
    f:	text;
    l:	String;
    p:	String;
    e:	Byte;
    
begin
    write('[*] Loading config file (',HW_CONFIG,'): ');
    
    assign(f, HW_CONFIG);
    {$I-}reset(f);{$I+}
    if (IOResult <> 0) then
    begin
	writeln('Failed.');
	exit;
    end else
	writeln('OK');
    
    while not (eof(f)) do
    begin
	readln(f,l);
	
	if (l[1] = '#') or (l[2] = '#') then
	    readln(f, l);
	
	if (copy(l, 1, 7) = 'plugin=') then
	begin
	    p:=trim(copy(l, pos('=',l)+1, length(l)));
	    
	    if (pos('/',p) <> 0) then
		e:=hwLoadPlugin(p)
	    else
		e:=hwLoadPlugin(HW_PLUGINS+p);
	end;
	
	if (copy(l, 1,5) = 'nick=') then
	begin
	    p:=trim(copy(l, pos('=',l)+1, length(l)));
	    
	    if (p <> '') then
		HW_NICK:=p;
	end;
	
	if (copy(l, 1,14) = 'plugins_patch=') then
	begin
	    p:=trim(copy(l, pos('=',l)+1, length(l)));
	    
	    if (p[length(p)] <> '/') then
		p+='/';
	    
	    if (p <> '') then
		HW_PLUGINS:=p;
	end;
	
	
	if (copy(l, 1, 5) = 'room=') then
	begin
	    p:=trim(copy(l, pos('=',l)+1, length(l)));
	    
	    if (p <> '') then
		HW_ROOM:=p;
	end;
	
	if (copy(l, 1, 9) = 'password=') then
	begin
	    p:=trim(copy(l, pos('=',l)+1, length(l)));
	    
	    if (p <> '') then
		HW_PASSWORD:=p;
	end;
    end;
    
    close(f);
end;
 
 
begin
    writeln('[@] InfoBOT for Hedgewars by Solaris (solargrim@gmail.com) ver. ',VERSION);
    
    HW_NICK:='INFOBOT';
    HW_ROOM:=HW_NICK+' ROOM';
    
    SetLength(plugin, HW_MAXPLUGINS);
    SetLength(user, HW_MAXUSERS);
    pc:=0;
    GetDir(0, HW_PLUGINS);
    HW_PLUGINS+='/plugins/';

    hwLoadConfig();
    hwinfo();
    hwConnect();
    hwRegister();
    hwInitPlugins();
    hwLoop();
    hwDisconnect();
end.
