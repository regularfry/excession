require 'test/helper'

require 'excession/css_regex_hue_mod'

module TestExcession
  class TestCssRegexHueMod < Test::Unit::TestCase
    include Excession

    def setup
      @m = CssRegexHueMod.new
    end

    def test_rgb_to_hsl

      assert_equal( [0,0,0], 
                    @m.rgb_to_hsl([0,0,0]) )
      h,s,l = @m.rgb_to_hsl([0.83, 0.07, 0.07].map{|i| i*255})
      assert_equal 0, h
      assert (s-0.84).abs < 0.01
      assert (l-0.45).abs < 0.01

    end

    def test_rgb_to_hsl_white
      assert_equal [0,0,1.0], @m.rgb_to_hsl([255,255,255])
    end

    def test_rgb_to_hsl_red
      assert_equal [0,1,0.5], @m.rgb_to_hsl([255,0,0])
    end

    def test_hsl_to_rgb
      assert_equal( [0,0,0],
                    @m.hsl_to_rgb([0,0,0]) )
      assert_equal [211, 18, 18], @m.hsl_to_rgb([0,0.84,0.45])
      assert_equal( [0,255,0], @m.hsl_to_rgb([120,1,0.5]) )
      assert_equal( [0,0,255], @m.hsl_to_rgb([-120,1,0.5]) )
    end

    def test_rgb_to_hashsix
      assert_equal "#ffffff", @m.rgb_to_hashsix([255,255,255])
      assert_equal "#000000", @m.rgb_to_hashsix([0,0,0])
    end

    def test_modify_rgb
      
      result = @m.modify_rgb([255,255,255]){|hsl| h,s,l=*hsl; [180,s,l]}
      assert_equal "#ffffff", result
    end

    def test_replace_colours_hashsix
      orig = "background-color: #ff0000;"
      target = "background-color: #00ff00;"
      assert_equal(target, @m.replace_colours(orig){|hsl| h,s,l=*hsl; [h+120,s,l]})
    end

    def test_replace_colours_hashthree
      orig = "color: #f00}"
      target = "color: #00ff00}"
      assert_equal(target, @m.replace_colours(orig){|hsl| h,s,l=*hsl; [h+120,s,l]})
    end

    def test_replace_colours_rgb
      orig = "color: rgb(255,0,0);"
      target = "color: #00ff00;"
      assert_equal(target, @m.replace_colours(orig){|hsl| h,s,l=*hsl; [h+120,s,l]})
    end

    def test_replace_colours_rgbpct
      orig = "color: rgb(100%,0%,0%);"
      target = "color: #00ff00;"
      assert_equal(target, @m.replace_colours(orig){|hsl| h,s,l=*hsl; [h+120,s,l]})    
    end

=begin
       def test_replace_colours_name
         orig = "color: red;"
         target = "color: #00ff00;"
         assert_equal(target, @m.replace_colours(orig){|h,s,l| [h+120,s,l]})
       end
=end

   end # class TestCssRegexHueMod
end # module TestExcession
