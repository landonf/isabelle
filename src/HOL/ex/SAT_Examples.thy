(*  Title:      HOL/ex/SAT_Examples.thy
    ID:         $Id$
    Author:     Alwen Tiu, Tjark Weber
    Copyright   2005
*)

header {* Examples for the 'sat' command *}

theory SAT_Examples imports Main

begin

(* Translated from TPTP problem library: PUZ015-2.006.dimacs *)

lemma assumes 1: "~x0"
and 2: "~x30"
and 3: "~x29"
and 4: "~x59"
and 5: "x1 | x31 | x0"
and 6: "x2 | x32 | x1"
and 7: "x3 | x33 | x2"
and 8: "x4 | x34 | x3"
and 9: "x35 | x4"
and 10: "x5 | x36 | x30"
and 11: "x6 | x37 | x5 | x31"
and 12: "x7 | x38 | x6 | x32"
and 13: "x8 | x39 | x7 | x33"
and 14: "x9 | x40 | x8 | x34"
and 15: "x41 | x9 | x35"
and 16: "x10 | x42 | x36"
and 17: "x11 | x43 | x10 | x37"
and 18: "x12 | x44 | x11 | x38"
and 19: "x13 | x45 | x12 | x39"
and 20: "x14 | x46 | x13 | x40"
and 21: "x47 | x14 | x41"
and 22: "x15 | x48 | x42"
and 23: "x16 | x49 | x15 | x43"
and 24: "x17 | x50 | x16 | x44"
and 25: "x18 | x51 | x17 | x45"
and 26: "x19 | x52 | x18 | x46"
and 27: "x53 | x19 | x47"
and 28: "x20 | x54 | x48"
and 29: "x21 | x55 | x20 | x49"
and 30: "x22 | x56 | x21 | x50"
and 31: "x23 | x57 | x22 | x51"
and 32: "x24 | x58 | x23 | x52"
and 33: "x59 | x24 | x53"
and 34: "x25 | x54"
and 35: "x26 | x25 | x55"
and 36: "x27 | x26 | x56"
and 37: "x28 | x27 | x57"
and 38: "x29 | x28 | x58"
and 39: "~x1 | ~x31"
and 40: "~x1 | ~x0"
and 41: "~x31 | ~x0"
and 42: "~x2 | ~x32"
and 43: "~x2 | ~x1"
and 44: "~x32 | ~x1"
and 45: "~x3 | ~x33"
and 46: "~x3 | ~x2"
and 47: "~x33 | ~x2"
and 48: "~x4 | ~x34"
and 49: "~x4 | ~x3"
and 50: "~x34 | ~x3"
and 51: "~x35 | ~x4"
and 52: "~x5 | ~x36"
and 53: "~x5 | ~x30"
and 54: "~x36 | ~x30"
and 55: "~x6 | ~x37"
and 56: "~x6 | ~x5"
and 57: "~x6 | ~x31"
and 58: "~x37 | ~x5"
and 59: "~x37 | ~x31"
and 60: "~x5 | ~x31"
and 61: "~x7 | ~x38"
and 62: "~x7 | ~x6"
and 63: "~x7 | ~x32"
and 64: "~x38 | ~x6"
and 65: "~x38 | ~x32"
and 66: "~x6 | ~x32"
and 67: "~x8 | ~x39"
and 68: "~x8 | ~x7"
and 69: "~x8 | ~x33"
and 70: "~x39 | ~x7"
and 71: "~x39 | ~x33"
and 72: "~x7 | ~x33"
and 73: "~x9 | ~x40"
and 74: "~x9 | ~x8"
and 75: "~x9 | ~x34"
and 76: "~x40 | ~x8"
and 77: "~x40 | ~x34"
and 78: "~x8 | ~x34"
and 79: "~x41 | ~x9"
and 80: "~x41 | ~x35"
and 81: "~x9 | ~x35"
and 82: "~x10 | ~x42"
and 83: "~x10 | ~x36"
and 84: "~x42 | ~x36"
and 85: "~x11 | ~x43"
and 86: "~x11 | ~x10"
and 87: "~x11 | ~x37"
and 88: "~x43 | ~x10"
and 89: "~x43 | ~x37"
and 90: "~x10 | ~x37"
and 91: "~x12 | ~x44"
and 92: "~x12 | ~x11"
and 93: "~x12 | ~x38"
and 94: "~x44 | ~x11"
and 95: "~x44 | ~x38"
and 96: "~x11 | ~x38"
and 97: "~x13 | ~x45"
and 98: "~x13 | ~x12"
and 99: "~x13 | ~x39"
and 100: "~x45 | ~x12"
and 101: "~x45 | ~x39"
and 102: "~x12 | ~x39"
and 103: "~x14 | ~x46"
and 104: "~x14 | ~x13"
and 105: "~x14 | ~x40"
and 106: "~x46 | ~x13"
and 107: "~x46 | ~x40"
and 108: "~x13 | ~x40"
and 109: "~x47 | ~x14"
and 110: "~x47 | ~x41"
and 111: "~x14 | ~x41"
and 112: "~x15 | ~x48"
and 113: "~x15 | ~x42"
and 114: "~x48 | ~x42"
and 115: "~x16 | ~x49"
and 116: "~x16 | ~x15"
and 117: "~x16 | ~x43"
and 118: "~x49 | ~x15"
and 119: "~x49 | ~x43"
and 120: "~x15 | ~x43"
and 121: "~x17 | ~x50"
and 122: "~x17 | ~x16"
and 123: "~x17 | ~x44"
and 124: "~x50 | ~x16"
and 125: "~x50 | ~x44"
and 126: "~x16 | ~x44"
and 127: "~x18 | ~x51"
and 128: "~x18 | ~x17"
and 129: "~x18 | ~x45"
and 130: "~x51 | ~x17"
and 131: "~x51 | ~x45"
and 132: "~x17 | ~x45"
and 133: "~x19 | ~x52"
and 134: "~x19 | ~x18"
and 135: "~x19 | ~x46"
and 136: "~x52 | ~x18"
and 137: "~x52 | ~x46"
and 138: "~x18 | ~x46"
and 139: "~x53 | ~x19"
and 140: "~x53 | ~x47"
and 141: "~x19 | ~x47"
and 142: "~x20 | ~x54"
and 143: "~x20 | ~x48"
and 144: "~x54 | ~x48"
and 145: "~x21 | ~x55"
and 146: "~x21 | ~x20"
and 147: "~x21 | ~x49"
and 148: "~x55 | ~x20"
and 149: "~x55 | ~x49"
and 150: "~x20 | ~x49"
and 151: "~x22 | ~x56"
and 152: "~x22 | ~x21"
and 153: "~x22 | ~x50"
and 154: "~x56 | ~x21"
and 155: "~x56 | ~x50"
and 156: "~x21 | ~x50"
and 157: "~x23 | ~x57"
and 158: "~x23 | ~x22"
and 159: "~x23 | ~x51"
and 160: "~x57 | ~x22"
and 161: "~x57 | ~x51"
and 162: "~x22 | ~x51"
and 163: "~x24 | ~x58"
and 164: "~x24 | ~x23"
and 165: "~x24 | ~x52"
and 166: "~x58 | ~x23"
and 167: "~x58 | ~x52"
and 168: "~x23 | ~x52"
and 169: "~x59 | ~x24"
and 170: "~x59 | ~x53"
and 171: "~x24 | ~x53"
and 172: "~x25 | ~x54"
and 173: "~x26 | ~x25"
and 174: "~x26 | ~x55"
and 175: "~x25 | ~x55"
and 176: "~x27 | ~x26"
and 177: "~x27 | ~x56"
and 178: "~x26 | ~x56"
and 179: "~x28 | ~x27"
and 180: "~x28 | ~x57"
and 181: "~x27 | ~x57"
and 182: "~x29 | ~x28"
and 183: "~x29 | ~x58"
and 184: "~x28 | ~x58"
shows "False"
using 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 
20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 
40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 
60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 
80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 
100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 
120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 
140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 
160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 
180 181 182 183 184 
by sat

end
