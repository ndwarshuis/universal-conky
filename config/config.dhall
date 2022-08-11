let Vector2 = \(a : Type) -> { x : a, y : a }

let Point = Vector2 Natural

let Margin = Vector2 Natural

let FSPath = { name : Text, path : Text }

let FileSystem = { show_smart : Bool, fs_paths : List FSPath }

let Graphics =
      { dev_power : Text
      , show_temp : Bool
      , show_clock : Bool
      , show_gpu_util : Bool
      , show_mem_util : Bool
      , show_vid_util : Bool
      }

let Memory =
      { show_stats : Bool
      , show_plot : Bool
      , show_swap : Bool
      , table_rows : Natural
      }

let Processor =
      { core_rows : Natural
      , core_padding : Natural
      , show_stats : Bool
      , show_plot : Bool
      , table_rows : Natural
      }

let RaplSpec = { name : Text, address : Text }

let Power = { battery : Text, rapl_specs : List RaplSpec }

let ReadWrite = { devices : List Text }

let Modules =
      { Type =
          { filesystem : Optional FileSystem
          , graphics : Optional Graphics
          , memory : Optional Memory
          , processor : Optional Processor
          , power : Optional Power
          , readwrite : Optional ReadWrite
          }
      , default =
        { filesystem = None FileSystem
        , graphics = None Graphics
        , memory = None Memory
        , processor = None Processor
        , power = None Power
        , readwrite = None ReadWrite
        }
      }

let ModType =
      < fileSystem
      | graphics
      | memory
      | network
      | pacman
      | processor
      | readwrite
      | system
      >

let Block = < Pad : Natural | Mod : ModType >

let Column = { blocks : List Block, width : Natural }

let Panel = { columns : List Column, margins : Margin }

let Layout = { anchor : Point, panels : List Panel }

let Sizes =
      { Type =
          { normal : Natural
          , plot_label : Natural
          , table : Natural
          , header : Natural
          }
      , default = { normal = 13, plot_label = 8, table = 11, header = 15 }
      }

let Font =
      { Type = { family : Text, sizes : Sizes.Type }
      , default = { family = "Neuropolitical", sizes = Sizes::{=} }
      }

let PlotGeometry =
      { Type =
          { spacing : Natural
          , height : Natural
          , seconds : Natural
          , ticks : Vector2 Natural
          }
      , default =
        { seconds = 90, ticks = { x = 9, y = 4 }, height = 56, spacing = 20 }
      }

let TableGeometry =
      { Type =
          { name_chars : Natural
          , padding : Margin
          , header_padding : Natural
          , row_spacing : Natural
          }
      , default =
        { name_chars = 8
        , padding = { x = 6, y = 15 }
        , header_padding = 20
        , row_spacing = 13
        }
      }

let HeaderGeometry =
      { Type = { underline_offset : Natural, padding : Natural }
      , default = { underline_offset = 26, padding = 19 }
      }

let Geometry =
      { Type =
          { plot : PlotGeometry.Type
          , table : TableGeometry.Type
          , header : HeaderGeometry.Type
          }
      , default =
        { plot = PlotGeometry::{=}
        , table = TableGeometry::{=}
        , header = HeaderGeometry::{=}
        }
      }

let StopRGB = { color : Natural, stop : Double }

let StopRGBA = { color : Natural, stop : Double, alpha : Double }

let ColorAlpha = { color : Natural, alpha : Double }

let Pattern =
      < RGB : Natural
      | RGBA : ColorAlpha
      | GradientRGB : List StopRGB
      | GradientRGBA : List StopRGBA
      >

let Patterns =
      { Type =
          { header : Pattern
          , panel : { bg : Pattern }
          , text : { active : Pattern, inactive : Pattern, critical : Pattern }
          , border : Pattern
          , plot :
              { grid : Pattern
              , outline : Pattern
              , data : { border : Pattern, fill : Pattern }
              }
          , indicator :
              { bg : Pattern, fg : { active : Pattern, inactive : Pattern } }
          }
      , default =
        { header = Pattern.RGB 0xefefef
        , panel.bg = Pattern.RGBA { color = 0x121212, alpha = 0.7 }
        , text =
          { active = Pattern.RGB 0xbfe1ff
          , inactive = Pattern.RGB 0xc8c8c8
          , critical = Pattern.RGB 0xff8282
          }
        , border = Pattern.RGB 0x888888
        , plot =
          { grid = Pattern.RGB 0x666666
          , outline = Pattern.RGB 0x777777
          , data =
            { border =
                Pattern.GradientRGB
                  [ { color = 0x003f7c, stop = 0.0 }
                  , { color = 0x1e90ff, stop = 1.0 }
                  ]
            , fill =
                Pattern.GradientRGBA
                  [ { color = 0x316ece, stop = 0.2, alpha = 0.5 }
                  , { color = 0x8cc7ff, stop = 1.0, alpha = 1.0 }
                  ]
            }
          }
        , indicator =
          { bg =
              Pattern.GradientRGB
                [ { color = 0x565656, stop = 0.0 }
                , { color = 0xbfbfbf, stop = 0.5 }
                , { color = 0x565656, stop = 1.0 }
                ]
          , fg =
            { active =
                Pattern.GradientRGB
                  [ { color = 0x316BA6, stop = 0.0 }
                  , { color = 0x99CEFF, stop = 0.5 }
                  , { color = 0x316BA6, stop = 1.0 }
                  ]
            , inactive =
                Pattern.GradientRGB
                  [ { color = 0xFF3333, stop = 0.0 }
                  , { color = 0xFFB8B8, stop = 0.5 }
                  , { color = 0xFF3333, stop = 1.0 }
                  ]
            }
          }
        }
      }

let Theme =
      { Type =
          { font : Font.Type
          , geometry : Geometry.Type
          , patterns : Patterns.Type
          }
      , default =
        { font = Font::{=}, geometry = Geometry::{=}, patterns = Patterns::{=} }
      }

let Bootstrap = { update_interval : Natural, dimensions : Point }

let Config =
      { bootstrap : Bootstrap
      , theme : Theme.Type
      , layout : Layout
      , modules : Modules.Type
      }

let toConfig =
      \(i : Natural) ->
      \(d : Point) ->
      \(t : Theme.Type) ->
      \(l : Layout) ->
      \(m : Modules.Type) ->
          { bootstrap = { update_interval = i, dimensions = d }
          , theme = t
          , layout = l
          , modules = m
          }
        : Config

in  { toConfig
    , Block
    , ModType
    , Layout
    , Panel
    , Modules
    , FSPath
    , FileSystem
    , Graphics
    , Memory
    , Processor
    , Power
    , ReadWrite
    , Theme
    }
