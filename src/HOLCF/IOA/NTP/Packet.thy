(*  Title:      HOL/IOA/NTP/Packet.thy
    ID:         $Id$
    Author:     Tobias Nipkow & Konrad Slind
    License:    GPL (GNU GENERAL PUBLIC LICENSE)

Packets.
*)

Packet = Multiset +  

types

   'msg packet = "bool * 'msg"

constdefs

  hdr  :: 'msg packet => bool
  "hdr == fst"

  msg :: 'msg packet => 'msg
  "msg == snd"

end
