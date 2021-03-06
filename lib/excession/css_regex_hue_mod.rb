module Excession
  class CssRegexHueMod

    HASHSIX = /#([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})(\s|;|})/i
    HASHTHREE = /#([a-f0-9])([a-f0-9])([a-f0-9])(\s|;|})/i
    RGBCALL = /rgb\(\s*(-?[0-9]+)\s*,\s*(-?[0-9]+)\s*,\s*(-?[0-9]+)\)/i
    RGBPCTCALL = /rgb\(\s*(-?[0-9]+)\s*%\s*,\s*(-?[0-9]+)\s*%\s*,\s*(-?[0-9]+)\s*%\s*\)/i


    # Use this entry point.
    def rotate_hue(angle_degrees, str)
      replace_colours(str) do |hsl| 
        h,s,l = *hsl
        [h+angle_degrees, s, l]
      end
    end



    def rgb_to_hsl(rgbint)
      rgb = rgbint.map{|i| i/255.0}
      maxcolour = rgb.max
      mincolour = rgb.min

      #puts "maxcolour: #{maxcolour}"
      #puts "mincolour: #{mincolour}"

      cdiff = (maxcolour-mincolour)
      csum = (maxcolour + mincolour)

      #puts "cdiff: #{cdiff}"
      #puts "csum: #{csum}"

      l = csum/2
      #puts "l: #{l}"
      h,s = 0,0
      if maxcolour != mincolour
        s = l < 0.5 ? cdiff/csum : cdiff/(2.0-csum)
        #puts "s: #{s}"
        r,g,b = rgb
        h = if r == maxcolour
              (g-b)/cdiff
            elsif g == maxcolour
              2.0+(b-r)/cdiff
            else
              4.0+(r-g)/cdiff
            end
        #puts "h: #{h}"
      end

      return [(h*360)%360,s,l]
    end

    def hsl_to_rgb(hsl)
      hdeg,s,l = *hsl

      rgb = nil
      if s == 0
        rgb = [l,l,l]
      else
        temp2 =  l < 0.5 ? l*(1+s) : l+s-l*s
        temp1 = 2.0*l-temp2
        h = hdeg/360.0
        temp3 = [h+1.0/3.0, h, h-1.0/3.0].map{|i| i < 0 ? i+1 : (i > 1 ? i-1 : i)}
        rgb = temp3.map do |i|
          if 6.0*i < 1
            temp1 + (temp2-temp1)*6.0*i
          elsif 2*i < 1
            temp2
          elsif 3*i < 2
            temp1 + (temp2-temp1)*((2.0/3.0)-i)*6.0
          else
            temp1
          end
        end
      end
      rgb.map{|i| (i*255).floor}
    end

    def rgb_to_hashsix(rgb)
      "#" + rgb.map do |i| 
        str = i.to_s(16)
        raise "Invalid colour (#{rgb.inspect})!" if str.length > 2
        str="0"+str if str.length<2
        str
      end.join
    end

    def modify_hsl(hsl, &blk)
      newhsl = blk.call(hsl)
      newhsl[0] %= 360
      newhsl
    end

    def modify_rgb(rgb, &blk)
      rgb_to_hashsix(hsl_to_rgb(modify_hsl(rgb_to_hsl(rgb), &blk)))
    end

    def replace_colours(str, &blk)

      str.gsub!(HASHSIX) do
        hexr, hexg, hexb, tend = $1, $2, $3, $4
        modify_rgb([hexr, hexg, hexb].map(&:hex), &blk)+tend
      end

      str.gsub!(HASHTHREE) do 
        hexr, hexg, hexb, tend = $1, $2, $3, $4
        modify_rgb([hexr*2,hexg*2,hexb*2].map(&:hex), &blk)+tend
      end

      str.gsub!(RGBCALL) do
        strr, strg, strb = $1, $2, $3
        modify_rgb([strr, strg, strb].map{|s|Integer(s)}, &blk)
      end
      
      str.gsub!(RGBPCTCALL) do
        strr, strg, strb = $1, $2, $3
        modify_rgb([strr, strg, strb].
                   map{|s|Integer(s)}.
                   map{|i| (i/100.0) * 255 }, # Don't just multiply by 2.55, it's not accurate
                   &blk)
      end
      
      str
    end

  end # class CssRegexHueMod
end # module Excession


=begin
COLOUR_LOOKUP = {
  "AliceBlue" =>"#F0F8FF",
  "AntiqueWhite" =>"#FAEBD7",
  "Aqua" =>"#00FFFF",
  "Aquamarine" =>"#7FFFD4",
  "Azure" =>"#F0FFFF",
  "Beige" =>"#F5F5DC",
  "Bisque" =>"#FFE4C4",
  "Black" =>"#000000",
  "BlanchedAlmond" =>"#FFEBCD",
  "Blue" =>"#0000FF",
  "BlueViolet" =>"#8A2BE2",
  "Brown" =>"#A52A2A",
  "BurlyWood" =>"#DEB887",
  "CadetBlue" =>"#5F9EA0",
  "Chartreuse" =>"#7FFF00",
  "Chocolate" =>"#D2691E",
  "Coral" =>"#FF7F50",
  "CornflowerBlue" =>"#6495ED",
  "Cornsilk" =>"#FFF8DC",
  "Crimson" =>"#DC143C",
  "Cyan" =>"#00FFFF",
  "DarkBlue" =>"#00008B",
  "DarkCyan" =>"#008B8B",
  "DarkGoldenRod" =>"#B8860B",
  "DarkGray" =>"#A9A9A9",
  "DarkGrey" =>"#A9A9A9",
  "DarkGreen" =>"#006400",
  "DarkKhaki" =>"#BDB76B",
  "DarkMagenta" =>"#8B008B",
  "DarkOliveGreen" =>"#556B2F",
  "Darkorange" =>"#FF8C00",
  "DarkOrchid" =>"#9932CC",
  "DarkRed" =>"#8B0000",
  "DarkSalmon" =>"#E9967A",
  "DarkSeaGreen" =>"#8FBC8F",
  "DarkSlateBlue" =>"#483D8B",
  "DarkSlateGray" =>"#2F4F4F",
  "DarkSlateGrey" =>"#2F4F4F",
  "DarkTurquoise" =>"#00CED1",
  "DarkViolet" =>"#9400D3",
  "DeepPink" =>"#FF1493",
  "DeepSkyBlue" =>"#00BFFF",
  "DimGray" =>"#696969",
  "DimGrey" =>"#696969",
  "DodgerBlue" =>"#1E90FF",
  "FireBrick" =>"#B22222",
  "FloralWhite" =>"#FFFAF0",
  "ForestGreen" =>"#228B22",
  "Fuchsia" =>"#FF00FF",
  "Gainsboro" =>"#DCDCDC",
  "GhostWhite" =>"#F8F8FF",
  "Gold" =>"#FFD700",
  "GoldenRod" =>"#DAA520",
  "Gray" =>"#808080",
  "Grey" =>"#808080",
  "Green" =>"#008000",
  "GreenYellow" =>"#ADFF2F",
  "HoneyDew" =>"#F0FFF0",
  "HotPink" =>"#FF69B4",
  "IndianRed" =>"#CD5C5C",
  "Indigo" =>"#4B0082",
  "Ivory" =>"#FFFFF0",
  "Khaki" =>"#F0E68C",
  "Lavender" =>"#E6E6FA",
  "LavenderBlush" =>"#FFF0F5",
  "LawnGreen" =>"#7CFC00",
  "LemonChiffon" =>"#FFFACD",
  "LightBlue" =>"#ADD8E6",
  "LightCoral" =>"#F08080",
  "LightCyan" =>"#E0FFFF",
  "LightGoldenRodYellow" =>"#FAFAD2",
  "LightGray" =>"#D3D3D3",
  "LightGrey" =>"#D3D3D3",
  "LightGreen" =>"#90EE90",
  "LightPink" =>"#FFB6C1",
  "LightSalmon" =>"#FFA07A",
  "LightSeaGreen" =>"#20B2AA",
  "LightSkyBlue" =>"#87CEFA",
  "LightSlateGray" =>"#778899",
  "LightSlateGrey" =>"#778899",
  "LightSteelBlue" =>"#B0C4DE",
  "LightYellow" =>"#FFFFE0",
  "Lime" =>"#00FF00",
  "LimeGreen" =>"#32CD32",
  "Linen" =>"#FAF0E6",
  "Magenta" =>"#FF00FF",
  "Maroon" =>"#800000",
  "MediumAquaMarine" =>"#66CDAA",
  "MediumBlue" =>"#0000CD",
  "MediumOrchid" =>"#BA55D3",
  "MediumPurple" =>"#9370D8",
  "MediumSeaGreen" =>"#3CB371",
  "MediumSlateBlue" =>"#7B68EE",
  "MediumSpringGreen" =>"#00FA9A",
  "MediumTurquoise" =>"#48D1CC",
  "MediumVioletRed" =>"#C71585",
  "MidnightBlue" =>"#191970",
  "MintCream" =>"#F5FFFA",
  "MistyRose" =>"#FFE4E1",
  "Moccasin" =>"#FFE4B5",
  "NavajoWhite" =>"#FFDEAD",
  "Navy" =>"#000080",
  "OldLace" =>"#FDF5E6",
  "Olive" =>"#808000",
  "OliveDrab" =>"#6B8E23",
  "Orange" =>"#FFA500",
  "OrangeRed" =>"#FF4500",
  "Orchid" =>"#DA70D6",
  "PaleGoldenRod" =>"#EEE8AA",
  "PaleGreen" =>"#98FB98",
  "PaleTurquoise" =>"#AFEEEE",
  "PaleVioletRed" =>"#D87093",
  "PapayaWhip" =>"#FFEFD5",
  "PeachPuff" =>"#FFDAB9",
  "Peru" =>"#CD853F",
  "Pink" =>"#FFC0CB",
  "Plum" =>"#DDA0DD",
  "PowderBlue" =>"#B0E0E6",
  "Purple" =>"#800080",
  "Red" =>"#FF0000",
  "RosyBrown" =>"#BC8F8F",
  "RoyalBlue" =>"#4169E1",
  "SaddleBrown" =>"#8B4513",
  "Salmon" =>"#FA8072",
  "SandyBrown" =>"#F4A460",
  "SeaGreen" =>"#2E8B57",
  "SeaShell" =>"#FFF5EE",
  "Sienna" =>"#A0522D",
  "Silver" =>"#C0C0C0",
  "SkyBlue" =>"#87CEEB",
  "SlateBlue" =>"#6A5ACD",
  "SlateGray" =>"#708090",
  "SlateGrey" =>"#708090",
  "Snow" =>"#FFFAFA",
  "SpringGreen" =>"#00FF7F",
  "SteelBlue" =>"#4682B4",
  "Tan" =>"#D2B48C",
  "Teal" =>"#008080",
  "Thistle" =>"#D8BFD8",
  "Tomato" =>"#FF6347",
  "Turquoise" =>"#40E0D0",
  "Violet" =>"#EE82EE",
  "Wheat" =>"#F5DEB3",
  "White" =>"#FFFFFF",
  "WhiteSmoke" =>"#F5F5F5",
  "Yellow" =>"#FFFF00",
  "YellowGreen" =>"#9ACD32"
}
=end
