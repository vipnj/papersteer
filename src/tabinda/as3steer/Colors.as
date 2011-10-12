// ----------------------------------------------------------------------------
//
// PaperSteer - Papervision3D Port of OpenSteer
// Port by Mohammad Haseeb aka M.H.A.Q.S.
// http://www.tabinda.net
//
// OpenSteer -- Steering Behaviors for Autonomous Characters
//
// Copyright (c) 2002-2003, Sony Computer Entertainment America
// Original author: Craig Reynolds <craig_reynolds@playstation.sony.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//
//
// ----------------------------------------------------------------------------

package tabinda.as3steer
{
	public class Colors
	{
		/**
		 * Takes the following arguments
		 * @param	...args Vector3 - will split a Vector3 into RGB values and return a hex color
		 * 					r:int, g:int, b:int,a:int-optional
		 * @return uint - hex color value
		 */
		public static function toHex(...args):uint
		{
			var tmp:String;
			
			if (args.length == 3)
			{
				tmp = "0x" + args[0].toString( 16 ) + args[1].toString( 16 ) + args[2].toString( 16 );
				return uint(tmp);
			}
			else if(args.length == 1 && args[0] is Vector3)
			{
				tmp = "0x" + args[0].x.toString( 16 ) + args[0].y.toString( 16 ) + args[0].z.toString( 16 );
				return uint(tmp);
			}
			else
			{
				tmp = "0x" + args[0].toString(16) + args[1].toString( 16 ) + args[2].toString( 16 ) + args[3].toString( 16 );
				return uint(tmp);
			}
		}
		
		public static function toVector(arg:uint):Vector3
		{
			var r:int = uint(arg >> 16 & 0xFF);
			var g:int = uint(arg >> 8 & 0xFF)
			var b:int = uint(arg & 0xFF);
			return new Vector3(r, g, b);
		}
		
		public static const Black:uint = 0x000000;
		public static const White:uint = 0xFFFFFF;
		public static const Red:uint = 0xCC0000;
		public static const Yellow:uint = 0xFFFF00;
		public static const Green:uint = 0x00CC00;
		public static const Blue:uint = 0x0000FF;
		public static const Magenta:uint = 0x666699;
		public static const Orange:uint = 0xFF9900;
		public static const LightGray:uint = 0xD3D3D3;
		public static const DarkGray:uint = 0xA9A9A9;
		public static const Gray:uint = 0x888888;
        public static const AliceBlue:uint = 0xF0F8FF; 
        public static const AntiqueWhite:uint = 0xFAEBD7;
        public static const Aqua:uint =0x00FAFA;
        public static const Aquamarine:uint =0x7FFFD4;
        public static const Azure:uint =0xF0FFFF;
        public static const Beige:uint =0xF5F5DC;
        public static const Bisque:uint =0xFFE4C4;
        public static const BlanchedAlmond:uint =0xFFEBCD;
        public static const BlueViolet:uint =0x8A2BE2;
        public static const Brown:uint =0xA52A2A;
        public static const BurlyWood:uint =0xDEB887;
        public static const CadetBlue:uint =0x5F9EA0;
        public static const Chartreuse:uint =0x7FFF00;
        public static const Chocolate:uint =0xD2691E;
        public static const Coral:uint =0xFF7F50;
        public static const CornflowerBlue:uint =0x6495ED;
        public static const Cornsilk:uint =0xFFF8DC;
        public static const Crimson:uint =0xDC143C;
        public static const Cyan:uint =0x00FFFF;
        public static const DarkBlue:uint =0x00008B;
        public static const DarkCyan:uint =0x008B8B;
        public static const DarkGoldenrod:uint =0xB8870B;
        public static const DarkGreen:uint =0x006400;
        public static const DarkKhaki:uint =0xBDB76B;
        public static const DarkMagenta:uint =0x8B008B;
        public static const DarkOliveGreen:uint =0x556B2F;
        public static const DarkOrange:uint = 0xFF8C00;
        public static const DarkOrchid:uint = 0x9932CC;
        public static const DarkRed:uint = 0x8B0000;
        /*
        // Summary:
        //     Gets a system-defined color with the value R:233 G:150 B:122 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:233 G:150 B:122 A:255.
        public static const DarkSalmon:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:143 G:188 B:139 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:143 G:188 B:139 A:255.
        public static const DarkSeaGreen:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:72 G:61 B:139 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:72 G:61 B:139 A:255.
        public static const DarkSlateBlue:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:47 G:79 B:79 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:47 G:79 B:79 A:255.
        public static const DarkSlateGray:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:0 G:206 B:209 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:0 G:206 B:209 A:255.
        public static const DarkTurquoise:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:148 G:0 B:211 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:148 G:0 B:211 A:255.
        public static const DarkViolet:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:255 G:20 B:147 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:255 G:20 B:147 A:255.
        public static const DeepPink:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:0 G:191 B:255 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:0 G:191 B:255 A:255.
        public static const DeepSkyBlue:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:105 G:105 B:105 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:105 G:105 B:105 A:255.
        public static const DimGray:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:30 G:144 B:255 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:30 G:144 B:255 A:255.
        public static const DodgerBlue:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:178 G:34 B:34 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:178 G:34 B:34 A:255.
        public static const Firebrick:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:255 G:250 B:240 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:255 G:250 B:240 A:255.
        public static const FloralWhite:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:34 G:139 B:34 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:34 G:139 B:34 A:255.
        public static const ForestGreen:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:255 G:0 B:255 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:255 G:0 B:255 A:255.
        public static const Fuchsia:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:220 G:220 B:220 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:220 G:220 B:220 A:255.
        public static const Gainsboro:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:248 G:248 B:255 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:248 G:248 B:255 A:255.
        public static const GhostWhite:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:255 G:215 B:0 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:255 G:215 B:0 A:255.
        public static const Gold:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:218 G:165 B:32 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:218 G:165 B:32 A:255.
        public static const Goldenrod:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:128 G:128 B:128 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:128 G:128 B:128 A:255.
        public static const Gray:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:0 G:128 B:0 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:0 G:128 B:0 A:255.
        public static const Green:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:173 G:255 B:47 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:173 G:255 B:47 A:255.
        public static const GreenYellow:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:240 G:255 B:240 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:240 G:255 B:240 A:255.
        public static const Honeydew:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:255 G:105 B:180 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:255 G:105 B:180 A:255.
        public static const HotPink:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:205 G:92 B:92 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:205 G:92 B:92 A:255.
        public static const IndianRed:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:75 G:0 B:130 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:75 G:0 B:130 A:255.
        public static const Indigo:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:255 G:255 B:240 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:255 G:255 B:240 A:255.
        public static const Ivory:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:240 G:230 B:140 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:240 G:230 B:140 A:255.
        public static const Khaki:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:230 G:230 B:250 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:230 G:230 B:250 A:255.
        public static const Lavender:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:255 G:240 B:245 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:255 G:240 B:245 A:255.
        public static const LavenderBlush:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:124 G:252 B:0 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:124 G:252 B:0 A:255.
        public static const LawnGreen:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:255 G:250 B:205 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:255 G:250 B:205 A:255.
        public static const LemonChiffon:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:173 G:216 B:230 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:173 G:216 B:230 A:255.
        public static const LightBlue:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:240 G:128 B:128 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:240 G:128 B:128 A:255.
        public static const LightCoral:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:224 G:255 B:255 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:224 G:255 B:255 A:255.
        public static const LightCyan:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:250 G:250 B:210 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:250 G:250 B:210 A:255.
        public static const LightGoldenrodYellow:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:211 G:211 B:211 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:211 G:211 B:211 A:255.
        public static const LightGray:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:144 G:238 B:144 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:144 G:238 B:144 A:255.
        public static const LightGreen:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:255 G:182 B:193 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:255 G:182 B:193 A:255.
        public static const LightPink:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:255 G:160 B:122 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:255 G:160 B:122 A:255.
        public static const LightSalmon:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:32 G:178 B:170 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:32 G:178 B:170 A:255.
        public static const LightSeaGreen:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:135 G:206 B:250 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:135 G:206 B:250 A:255.
        public static const LightSkyBlue:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:119 G:136 B:153 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:119 G:136 B:153 A:255.
        public static const LightSlateGray:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:176 G:196 B:222 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:176 G:196 B:222 A:255.
        public static const LightSteelBlue:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:255 G:255 B:224 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:255 G:255 B:224 A:255.
        public static const LightYellow:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:0 G:255 B:0 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:0 G:255 B:0 A:255.
        public static const Lime:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:50 G:205 B:50 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:50 G:205 B:50 A:255.
        public static const LimeGreen:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:250 G:240 B:230 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:250 G:240 B:230 A:255.
        public static const Linen:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:255 G:0 B:255 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:255 G:0 B:255 A:255.
        public static const Magenta:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:128 G:0 B:0 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:128 G:0 B:0 A:255.
        public static const Maroon:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:102 G:205 B:170 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:102 G:205 B:170 A:255.
        public static const MediumAquamarine:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:0 G:0 B:205 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:0 G:0 B:205 A:255.
        public static const MediumBlue:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:186 G:85 B:211 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:186 G:85 B:211 A:255.
        public static const MediumOrchid:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:147 G:112 B:219 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:147 G:112 B:219 A:255.
        public static const MediumPurple:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:60 G:179 B:113 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:60 G:179 B:113 A:255.
        public static const MediumSeaGreen:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:123 G:104 B:238 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:123 G:104 B:238 A:255.
        public static const MediumSlateBlue:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:0 G:250 B:154 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:0 G:250 B:154 A:255.
        public static const MediumSpringGreen:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:72 G:209 B:204 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:72 G:209 B:204 A:255.
        public static const MediumTurquoise:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:199 G:21 B:133 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:199 G:21 B:133 A:255.
        public static const MediumVioletRed:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:25 G:25 B:112 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:25 G:25 B:112 A:255.
        public static const MidnightBlue:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:245 G:255 B:250 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:245 G:255 B:250 A:255.
        public static const MintCream:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:255 G:228 B:225 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:255 G:228 B:225 A:255.
        public static const MistyRose:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:255 G:228 B:181 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:255 G:228 B:181 A:255.
        public static const Moccasin:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:255 G:222 B:173 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:255 G:222 B:173 A:255.
        public static const NavajoWhite:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color R:0 G:0 B:128 A:255.
        //
        // Returns:
        //     A system-defined color R:0 G:0 B:128 A:255.
        public static const Navy:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:253 G:245 B:230 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:253 G:245 B:230 A:255.
        public static const OldLace:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:128 G:128 B:0 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:128 G:128 B:0 A:255.
        public static const Olive:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:107 G:142 B:35 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:107 G:142 B:35 A:255.
        public static const OliveDrab:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:255 G:165 B:0 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:255 G:165 B:0 A:255.
        public static const Orange:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:255 G:69 B:0 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:255 G:69 B:0 A:255.
        public static const OrangeRed:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:218 G:112 B:214 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:218 G:112 B:214 A:255.
        public static const Orchid:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:238 G:232 B:170 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:238 G:232 B:170 A:255.
        public static const PaleGoldenrod:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:152 G:251 B:152 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:152 G:251 B:152 A:255.
        public static const PaleGreen:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:175 G:238 B:238 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:175 G:238 B:238 A:255.
        public static const PaleTurquoise:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:219 G:112 B:147 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:219 G:112 B:147 A:255.
        public static const PaleVioletRed:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:255 G:239 B:213 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:255 G:239 B:213 A:255.
        public static const PapayaWhip:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:255 G:218 B:185 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:255 G:218 B:185 A:255.
        public static const PeachPuff:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:205 G:133 B:63 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:205 G:133 B:63 A:255.
        public static const Peru:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:255 G:192 B:203 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:255 G:192 B:203 A:255.
        public static const Pink:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:221 G:160 B:221 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:221 G:160 B:221 A:255.
        public static const Plum:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:176 G:224 B:230 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:176 G:224 B:230 A:255.
        public static const PowderBlue:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:128 G:0 B:128 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:128 G:0 B:128 A:255.
        public static const Purple:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:255 G:0 B:0 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:255 G:0 B:0 A:255.
        public static const Red:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:188 G:143 B:143 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:188 G:143 B:143 A:255.
        public static const RosyBrown:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:65 G:105 B:225 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:65 G:105 B:225 A:255.
        public static const RoyalBlue:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:139 G:69 B:19 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:139 G:69 B:19 A:255.
        public static const SaddleBrown:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:250 G:128 B:114 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:250 G:128 B:114 A:255.
        public static const Salmon:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:244 G:164 B:96 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:244 G:164 B:96 A:255.
        public static const SandyBrown:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:46 G:139 B:87 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:46 G:139 B:87 A:255.
        public static const SeaGreen:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:255 G:245 B:238 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:255 G:245 B:238 A:255.
        public static const SeaShell:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:160 G:82 B:45 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:160 G:82 B:45 A:255.
        public static const Sienna:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:192 G:192 B:192 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:192 G:192 B:192 A:255.
        public static const Silver:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:135 G:206 B:235 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:135 G:206 B:235 A:255.
        public static const SkyBlue:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:106 G:90 B:205 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:106 G:90 B:205 A:255.
        public static const SlateBlue:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:112 G:128 B:144 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:112 G:128 B:144 A:255.
        public static const SlateGray:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:255 G:250 B:250 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:255 G:250 B:250 A:255.
        public static const Snow:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:0 G:255 B:127 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:0 G:255 B:127 A:255.
        public static const SpringGreen:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:70 G:130 B:180 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:70 G:130 B:180 A:255.
        public static const SteelBlue:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:210 G:180 B:140 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:210 G:180 B:140 A:255.
        public static const Tan:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:0 G:128 B:128 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:0 G:128 B:128 A:255.
        public static const Teal:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:216 G:191 B:216 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:216 G:191 B:216 A:255.
        public static const Thistle:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:255 G:99 B:71 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:255 G:99 B:71 A:255.
        public static const Tomato:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:0 G:0 B:0 A:0.
        //
        // Returns:
        //     A system-defined color with the value R:0 G:0 B:0 A:0.
        public static const TransparentBlack:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:255 G:255 B:255 A:0.
        //
        // Returns:
        //     A system-defined color with the value R:255 G:255 B:255 A:0.
        public static const TransparentWhite:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:64 G:224 B:208 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:64 G:224 B:208 A:255.
        public static const Turquoise:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:238 G:130 B:238 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:238 G:130 B:238 A:255.
        public static const Violet:uint = 0x
        //
        // Summary:
        //     Gets a system-defined color with the value R:245 G:222 B:179 A:255.
        //
        // Returns:
        //     A system-defined color with the value R:245 G:222 B:179 A:255.*/
        public static const Wheat:uint = 0xF5DEB3;
        public static const WhiteSmoke:uint = 0xF5F5F5;
        public static const YellowGreen:uint = 0x9ACD32;
	}
}