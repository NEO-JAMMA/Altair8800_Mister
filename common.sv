//`ifndef _CommonHeaderIncluded 
//`define _CommonHeaderIncluded 

// MENU - prg_sel will hold this eunm
  //	"O79,Select Program,Empty,zeroToseven,KillBits,SIOEcho,StatusLights,Basic4k32;",
	//  "OA,Enable TurnMon,No,Yes;",
  typedef enum {Empty='b000, zeroToseven='b001, KillBits='b010, SIOEcho='b011, StatusLights='b100, Basic4k32='b101} prg_type_enum;
  typedef enum {TurnMonOff='b0, TurnMonOn='b1} tun_mon_enum;

//`endif //_CommonHeaderIncluded 