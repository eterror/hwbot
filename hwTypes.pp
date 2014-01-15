
unit hwTypes;

interface

uses
    sockets,
    cthreads, cmem;


const
    HW_MAXUSERS	  = 2048;
    HW_MAXPLUGINS = 16;
    HW_PORT     = 46631;
    HW_PROTO    = 47;
    HW_CONFIG   = 'hw.conf';
    VERSION     = '0.3rc7';


var
    sAddr:      TInetSockAddr;
    S:          LongInt;
    sIn,
    sOut:       Text;
    i:          Integer;

    quit:       boolean;
    line:       String;
    motd:       AnsiString;

    HW_NICK:    String;
    HW_PLUGINS: String;
    HW_ROOM:    String;
    HW_PASSWORD:String;
    HW_ADMIN   :String;
    HW_NOTICES :String;
    HW_CMDCHAR :Char;
    HW_IP      :String;


type
    TUser = packed record
	mode:		String;
	nickname: 	String;
	upname:		String;
	srcip:		String;
    end;    

    TRoom = packed record
        password,
        owner, 
        mode,
        map, 
        scheme,
        weapons,
        users, 
        teams:   String;
    end;

implementation

begin
end.
