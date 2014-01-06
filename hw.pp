(*
 * InfoBOT, lobby commander (a bot a for Hedgewars lobby chat)
 * Copyright (c) 2013-12/2014 Solaris <solargrim@gmail.com>
*)

{$UNDEF DEBUG}
{$MODE OBJFPC}

{
TODO:
 - better support for NOTICE
 - better support for USER FLAGS (plugin command: onFlagChange)
 - sometimes bot use 100% of cpu (?)
}

program Hedgewars_InfoBOT(lobby, commander);

uses
    sysutils,
    dateutils,
    baseunix,
    strutils,
    hwTypes in 'hwTypes.pp',
    hwObjects in 'hwObjects.pp';
    
    
var
    hw:	THwbot;
 
 
procedure Main();cdecl;forward;
function Parse(input: String) : Boolean; forward;

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
	    hw.Reconnect();
	
	exit;
    end;
    
    
    if (input = 'NOTICE') then
    begin
	// hw.Reconnect(); {?}
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
	
	hw.uDelUser(s1);
	
	// plugin:OnQuit (like PartLobby)
	if (hw.pc <> 0) then    
	for k:=1 to (hw.pc) do
	    begin
		try
		    s8:=hw.plugin[k].onQuit(s1);
		    
		    if (length(s8) = 0) then
			continue;
			
		    writeln(sout, 'CHAT'+#10+s8, #10);
		except
		    continue;
		end;
	    end;
    
	if (s1 = HW_NICK) then
	begin
	    hw.Reconnect();
	    exit;
	end;
    end;
 
 
    if (input = 'JOINED') then 
    begin
	readln(sIn, s1);
	writeln('[#] ',s1,' joined to room.');
	
	// plugin:OnRoomJoin
	if (hw.pc <> 0) then    
	for k:=1 to (hw.pc) do
	    begin
		try
		    s8:=hw.plugin[k].onJoinRoom(s1);
		    
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
	if (hw.pc <> 0) then    
	for k:=1 to (hw.pc) do
	begin
	    try
		s8:=hw.plugin[k].OnJoinLobby(s1);
		    
		if (length(s8) = 0) then
		    continue;
			
		writeln(sout, 'CHAT'+#10,s8, #10);
	    except
		continue;
	    end;
	end;
    
	hw.uAddUser(s1, '+u');
	exit;
     end;
 
 
    if (input = 'CLIENT_FLAGS') then 
    begin
	readln(sin, s1);
	readln(sin, s2);
	writeln('[#] ',s2,': new user flag: ',s1);
	
	//uAddFlag
	
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
	    
	    if (HW_NOTICES = 'true') or (HW_NOTICES = '1') then	
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
	
	if (copy(s2, 1, (pos(':', s2)-1)) = HW_NICK) then
	begin
	    s8:=s2;
	    
	    for i:=1 to pos(':',s2) do
		delete(s8, 1, 1);
		
	    s8:=trimleft(s8);
	    s8:=trimright(s8);
	    s2:=s8;
	end;
    
	writeln('[#] [',TimeToStr(Now),'] ',s1,': ',s2);
  
	// Private bot commands
	if (copy(s2, 1, 5) = HW_CMDCHAR+'help') then
	begin
	    s3:=copy(s2, 7, length(s2));
	    s3:=trim(s3);
	    
	    // Custom help for plugins
	    if (hw.pc <> 0) and (s3 <> '') then    
	    begin
		for k:=1 to (hw.pc) do
		    if (s3 = trim(hw.plugin[k].name)) then
		    begin
			try 
			    writeln(sout, 'CHAT'+#10+'HELP ('+s3+'): '+hw.plugin[k].ghelp(), #10);
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
	    writeln(sout, 'CHAT');writeln(sout, '> '+HW_CMDCHAR+'help [command]',#10);
	    writeln(sOut, 'CHAT');writeln(sout, '> '+HW_CMDCHAR+'version',#10);
	    
	    // plugin:usage
	    if (hw.pc <> 0) then    
	    for k:=1 to (hw.pc) do
	    begin
		try
		    s8:=hw.plugin[k].cmd;
		    s8[1]:=HW_CMDCHAR;
		    writeln(sout, 'CHAT'+#10+'> '+s8+#32+hw.plugin[k].usage+' (Plugin)'+ #10);
		except
		    continue;
		end;
	    end;
	end;
        
        if (s2 = HW_CMDCHAR+'version') then 
	begin
	    writeln(sout, 'CHAT'+#10+'InfoBOT (hedgewars lobby commander) by solargrim@gmail.com, version: '+VERSION{$IFDEF DEBUG}+'-DEBUG'{$ENDIF},#10);
	    exit;
	end;
	
	if (ExtractWord(1, s2, [#32]) = HW_CMDCHAR+'reload') and (s1 = HW_ADMIN) then
	begin
	    if (hw.LoadConfig()) then
		writeln(sout, 'CHAT',#10, s1,': config reloaded.',#10) else
		writeln(sout, 'CHAT',#10, s1,': Failed to reload config.',#10);
		
	end;
	
	if (ExtractWord(1, s2, [#32]) = HW_CMDCHAR+'join') and (s1 = HW_ADMIN) then
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
	
	
	if (copy(s2, 1, 4) = HW_CMDCHAR+'raw') and (s1 = HW_ADMIN) then
	begin
	    s3:=copy(s2, 6, length(s2));
	    writeln('[*] Sending RAW DATA to server: ',s3);
	    
	    s4:=StringReplace(s3, '\n', #10, [rfReplaceAll]);
	    
	    if (s4[length(s4)] <> #10) then
		s4+=#10;
	    
	    if (s4 <> '') then
		writeln(sout, s4);
	end;
	
	
	if (copy(s2, 1, 5) = HW_CMDCHAR+'kick') and (s1 = HW_ADMIN) then
	begin
	    s3:=ExtractWord(2, s2, [#32]);
	    
	    if (s3 = HW_ADMIN) then
		exit;
	    
	    writeln('[*] Kicking user from room: ',s3);
	    writeln(sout, 'KICK',#10,s3,#10);
	    exit;
	end;
	
	
	if (s2 = HW_CMDCHAR+'op') and (s1 = HW_ADMIN) then
	begin
	    writeln('[*] Adding room operator status to bot admin');
	    writeln(sout, 'CMD');
	    writeln(sout, 'delegate ',HW_ADMIN,#10);
	    exit;
	end;
	
	
	if (s2 = HW_CMDCHAR+'part') and (s1 = HW_ADMIN) then
	begin
	    writeln(sout, 'PART',#10);
	    exit;
	end;
	
	
	if (s2 = HW_CMDCHAR+'die') then 
	begin
	    if (s1 = HW_ADMIN) then
	    begin
		quit:=True;
		exit;
	    end;
	    
	    writeln(sout,'CHAT');
		
	    if (random(2) = 1) then
		writeln(sout, 'No way ',s1,'!',#10) else
		writeln(sout, 'Try again later ',s1,'!',#10);
	end;
 
 
	if (s2 = HW_CMDCHAR+'fork') and (s1 = HW_ADMIN) then
	begin
	    writeln('[*] Clone: ',hwTypes.HW_NICK);
	    
	    fpFork();
	    fpExecVe('/home/users/solaris/hwbot/hw', nil, envp);
	end;
	
    
	if (copy(s2, 1,4)= HW_CMDCHAR+'say') and (s1 = HW_ADMIN) then 
	begin
	    if (ExtractWord(2, s2, [#32]) = '') then
		exit;
		
	    writeln(sout, 'CHAT');
	    writeln(sout, trim(copy(s2, 5, length(s2)))+#10);
	end;
    
    
	if (s2 = HW_CMDCHAR+'users') then 
	begin
	    writeln('USER LIST ->');
	
	    for i:=0 to high(hw.user) do 
		if (hw.user[i].nickname <> '') then
		    write(hw.user[i].nickname + '(',hw.user[i].mode,') ');
	end;
	
    
	if (ExtractWord(1, s2, [#32]) = HW_CMDCHAR+'set') then 
	begin
	    s7:=ExtractWord(2, s2, [#32]);
	    s8:=ExtractWord(3, s2, [#32]);
	    
	    if (s7 = '') and (s8 = '') then 
	    begin
		writeln(sout, 'CHAT',#10,s1,': cmdchar = ',HW_CMDCHAR,#10);
		writeln(sout, 'CHAT',#10,s1,': notices = ',HW_NOTICES,#10);
		exit;
	    end;

	    if (s7 <> '') and (s8 = '') then
	    begin
		if (s7 = 'cmdchar') then s5:=HW_CMDCHAR;
		if (s7 = 'notices') then s5:=HW_NOTICES;
		
		writeln(sout, 'CHAT',#10,s1+': ',s7,' = ',s5,#10);
		exit;
	    end;	
	    
	    if (s7 = 'cmdchar') then
		HW_CMDCHAR:=s8[1];
		
	    if (s7 = 'notices') then
		HW_NOTICES:=s8;
		
	    writeln(sout, 'CHAT',#10,s1+': variable ',s7,' set to ',s8,#10);	
	end;
    
 
	if (copy(s2, 1, 7) = HW_CMDCHAR+'plugin') and (s1 = HW_ADMIN) then
	begin
	    if (ExtractWord(2, s2, [#32]) = 'list') then
	    begin
	    	if (hw.pc = 0) then
		begin
		    writeln(sout, 'CHAT',#10,s1,': No plugins loaded.',#10);
		exit;
		end;
	    
		for k:=1 to (hw.pc) do
		begin
		    try
			if (hw.plugin[k].hnd <> 0) then
			    writeln(sout, 'CHAT'+#10+s1,': (',k,') ',hw.plugin[k].name,' -> ',hw.plugin[k].author,' (',hw.plugin[k].fname,'):',hw.plugin[k].ver,' (',hw.plugin[k].cmd,')'#10);
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
		
		case hw.plugin[i].Reload of
		    0: writeln(sout,'CHAT'+#10+s1+': Plugin '+hw.plugin[i].name+' reloaded.',#10);
		    1: writeln(sout,'CHAT'+#10+s1+': Failed to reload plugin (file not exists).',#10);
		    2: writeln(sout,'CHAT'+#10+s1+': Failed to reload plugin (not all functions defined).',#10);
		    3: writeln(sout,'CHAT'+#10+s1+': Failed to reload plugin (wtf?).',#10);
		end;
		
		exit;
	    end;
	    
	    if (ExtractWord(2, s2, [#32]) = 'load') then
	    begin
		writeln(sout, 'CHAT');
		
		s3:=HW_PLUGINS+ExtractWord(3, s2,[#32]);
		
		if (pos(s3, '.so') = 0) then
		    s3+='.so';
		    
		hw.pc+=1;
		
		with hw do plugin[pc]:=TPlugin.Create;
		
		case (hw.plugin[hw.pc].Load(s3)) of
		    0: begin
			    writeln(sout, s1,': Plugin loaded: ',hw.plugin[hw.pc].name+#10);
			    exit;
		       end;
		    1: writeln(sout, s1,': Plugin error: File does not exists.',#10);
		    2: writeln(sout, s1,': Plugin error: Failed to load library.',#10);
		    3: writeln(sout, s1,': Plugin error: Is not valid or deprecated.',#10);
		end;
		
		hw.pc-=1;
		exit;
	    end;
	    
	    if (ExtractWord(2, s2, [#32]) = 'unload') then
	    begin
		try
		    k:=StrToInt(ExtractWord(3, s2, [#32]));    
		except
		    exit;
		end;
		
		if (hw.plugin[k].Unload()) then
		    writeln(sout, 'CHAT',#10,s1,': Plugin removed.',#10)
		else
		    writeln(sout, 'CHAT',#10,s1,': Error while removing plugin.',#10);
	    end;
	end;
	
	
	// run plugins by defined command
	if (hw.pc <> 0) then    
	    for k:=1 to (hw.pc) do
	    begin
		s8:=hw.plugin[k].cmd;
		s8[1]:=HW_CMDCHAR;
		
		if (copy(s2, 1, pos(#32, s2)-1) = s8) or (s8 = s2) then
		begin
		    try 
			output:=hw.plugin[k].Parse(s1+':'+s2, hw.user, HW_NICK);
			
			if (length(output) <> 0) then
			    writeln(sout, 'CHAT'+#10,output, #10);
		    except
			continue;
		    end;
	    
		    exit;
		end;
	    end;
 
    end; // .private commands
 
 exit(TRUE);
end;


function hwLoop():boolean;
begin
    repeat
	readln(sIn, hwTypes.line);
	{$IFDEF DEBUG}if hwTypes.line<>'' then writeln(' -> "',hwTypes.line,'"');{$ENDIF}
	Parse(hwTypes.line);
    until (quit);
    
    exit(true);
end;


procedure RegisterSignal();
var
    oa, na:	PSigActionRec;
    
begin
    new(oa);
    new(na);
    na^.sa_Handler:=SigActionHandler(@Main);
    fillchar(na^.Sa_Mask,sizeof(na^.sa_mask),#0);
    na^.Sa_Flags:=0;
    {$IFDEF LINUX}na^.Sa_Restorer:=Nil;{$ENDIF}
    if fpSigAction(SigHup,na,oa) <> 0 then
	exit;
    dispose(oa);
    dispose(na);
end;


procedure Main(); cdecl;
begin
    writeln('[@] InfoBOT for Hedgewars by Solaris (solargrim@gmail.com) ver. ',VERSION);
    
    hw:=THwbot.Create;
    
    HW_NICK:='INFOBOT';
    HW_ROOM:=HW_NICK+' ROOM';
    HW_CMDCHAR:='.';
    HW_NOTICES:='true';
    
    SetLength(hw.plugin, HW_MAXPLUGINS);
    SetLength(hw.user, HW_MAXUSERS);
    hw.pc:=0;
    GetDir(0, HW_PLUGINS);
    HW_PLUGINS+='/plugins/';
    
    RegisterSignal();
    hw.LoadConfig();
    hw.info();
    hw.Connect();
    hw.Register();
    hw.InitPlugins();
    hwLoop();
    hw.Disconnect();
end;

 
begin
    Hedgewars_InfoBot.Main();
end.
