let Vector2 = \(a : Type) -> { x : a, y : a }

let Point = Vector2 Natural

let Margin = Vector2 Natural

let FSPath = { name : Text, path : Text }

let TextGeo = { Type = { text_spacing : Natural }, default.text_spacing = 20 }

let SepGeo = { Type = { sep_spacing : Natural }, default.sep_spacing = 20 }

let PlotGeo_ =
      { Type = { sec_break : Natural, height : Natural, ticks_y : Natural }
      , default = { sec_break = 20, height = 56, ticks_y = 4 }
      }

let PlotGeo = { Type = { plot : PlotGeo_.Type }, default.plot = PlotGeo_::{=} }

let TableGeo_ = { Type = { sec_break : Natural }, default.sec_break = 20 }

let TableGeo =
      { Type = { table : TableGeo_.Type }, default.table = TableGeo_::{=} }

let FSGeo =
      { Type = { bar_spacing : Natural, bar_pad : Natural } //\\ SepGeo.Type
      , default = { bar_spacing = 20, bar_pad = 100 } /\ SepGeo::{=}
      }

let GfxGeo =
      { Type = SepGeo.Type //\\ PlotGeo.Type //\\ TextGeo.Type
      , default = SepGeo::{=} /\ PlotGeo::{=} /\ TextGeo::{=}
      }

let MemGeo =
      { Type = TextGeo.Type //\\ PlotGeo.Type //\\ TableGeo.Type
      , default = TextGeo::{=} /\ PlotGeo::{=} /\ TableGeo::{=}
      }

let ProcGeo =
      { Type = GfxGeo.Type //\\ TableGeo.Type
      , default = GfxGeo::{=} /\ TableGeo::{=}
      }

let PwrGeo =
      { Type = TextGeo.Type //\\ PlotGeo.Type
      , default = TextGeo::{=} /\ PlotGeo::{=}
      }

let FileSystem =
      { Type =
          { show_smart : Bool, fs_paths : List FSPath, geometry : FSGeo.Type }
      , default.geometry = FSGeo::{=}
      }

let Graphics =
      { Type =
          { dev_power : Text
          , show_temp : Bool
          , show_clock : Bool
          , show_gpu_util : Bool
          , show_mem_util : Bool
          , show_vid_util : Bool
          , geometry : GfxGeo.Type
          }
      , default.geometry = GfxGeo::{=}
      }

let Memory =
      { Type =
          { show_stats : Bool
          , show_plot : Bool
          , show_swap : Bool
          , table_rows : Natural
          , geometry : MemGeo.Type
          }
      , default.geometry = MemGeo::{=}
      }

let Network =
      { Type = { geometry : PlotGeo.Type }, default.geometry = PlotGeo::{=} }

let Processor =
      { Type =
          { core_rows : Natural
          , core_padding : Natural
          , show_stats : Bool
          , show_plot : Bool
          , table_rows : Natural
          , geometry : ProcGeo.Type
          }
      , default.geometry = ProcGeo::{=}
      }

let RaplSpec = { name : Text, address : Text }

let Pacman =
      { Type = { geometry : TextGeo.Type }, default.geometry = TextGeo::{=} }

let Power =
      { Type =
          { battery : Text, rapl_specs : List RaplSpec, geometry : PwrGeo.Type }
      , default.geometry = PwrGeo::{=}
      }

let ReadWrite =
      { Type = { devices : List Text, geometry : PlotGeo.Type }
      , default.geometry = PlotGeo::{=}
      }

let System = Pacman

let ModType =
      < filesystem : FileSystem.Type
      | graphics : Graphics.Type
      | memory : Memory.Type
      | network : Network.Type
      | pacman : Pacman.Type
      | processor : Processor.Type
      | power : Power.Type
      | readwrite : ReadWrite.Type
      | system : System.Type
      >

let Annotated = \(a : Type) -> { type : Text, data : a }

let Block = < Pad : Natural | Mod : Annotated ModType >

let Column_ = { blocks : List Block, width : Natural }

let Column = < CPad : Natural | CCol : Column_ >

let Panel_ = { columns : List Column, margins : Margin }

let Panel = < PPad : Natural | PPanel : Panel_ >

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
          , ticks_x : Natural
          }
      , default = { seconds = 90, ticks_x = 9, height = 56, spacing = 20 }
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
        , row_spacing = 16
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

let annotatePattern =
      \(a : Pattern) ->
        { type = showConstructor a, data = a } : Annotated Pattern

let mod = \(a : ModType) -> Block.Mod { type = showConstructor a, data = a }

let APattern = Annotated Pattern

let symGradient =
      \(c0 : Natural) ->
      \(c1 : Natural) ->
        annotatePattern
          ( Pattern.GradientRGB
              [ { color = c0, stop = 0.0 }
              , { color = c1, stop = 0.5 }
              , { color = c0, stop = 1.0 }
              ]
          )

let Patterns =
      { Type =
          { header : APattern
          , panel : { bg : APattern }
          , text :
              { active : APattern, inactive : APattern, critical : APattern }
          , border : APattern
          , plot :
              { grid : APattern
              , outline : APattern
              , data : { border : APattern, fill : APattern }
              }
          , indicator :
              { bg : APattern, fg : { active : APattern, critical : APattern } }
          }
      , default =
        { header = annotatePattern (Pattern.RGB 0xefefef)
        , panel.bg
          = annotatePattern (Pattern.RGBA { color = 0x121212, alpha = 0.7 })
        , text =
          { active = annotatePattern (Pattern.RGB 0xbfe1ff)
          , inactive = annotatePattern (Pattern.RGB 0xc8c8c8)
          , critical = annotatePattern (Pattern.RGB 0xff8282)
          }
        , border = annotatePattern (Pattern.RGB 0x888888)
        , plot =
          { grid = annotatePattern (Pattern.RGB 0x666666)
          , outline = annotatePattern (Pattern.RGB 0x777777)
          , data =
            { border =
                annotatePattern
                  ( Pattern.GradientRGB
                      [ { color = 0x003f7c, stop = 0.0 }
                      , { color = 0x1e90ff, stop = 1.0 }
                      ]
                  )
            , fill =
                annotatePattern
                  ( Pattern.GradientRGBA
                      [ { color = 0x316ece, stop = 0.2, alpha = 0.5 }
                      , { color = 0x8cc7ff, stop = 1.0, alpha = 1.0 }
                      ]
                  )
            }
          }
        , indicator =
          { bg = symGradient 0x565656 0xbfbfbf
          , fg =
            { active = symGradient 0x316BA6 0x99CEFF
            , critical = symGradient 0xFF3333 0xFFB8B8
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

let Config = { bootstrap : Bootstrap, theme : Theme.Type, layout : Layout }

let toConfig =
      \(i : Natural) ->
      \(x : Natural) ->
      \(y : Natural) ->
      \(t : Theme.Type) ->
      \(l : Layout) ->
          { bootstrap = { update_interval = i, dimensions = { x, y } }
          , theme = t
          , layout = l
          }
        : Config

in  { toConfig
    , Block
    , Column
    , ModType
    , Layout
    , Panel
    , FSPath
    , FileSystem
    , Graphics
    , Memory
    , Network
    , Pacman
    , Processor
    , Power
    , ReadWrite
    , System
    , Theme
    , mod
    }
