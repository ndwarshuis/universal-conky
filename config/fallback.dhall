let C = ./config.dhall

let layout =
        { anchor = { x = 12, y = 11 }
        , panels =
              [ C.Panel.PPanel
                  { columns =
                    [ C.Column.CCol
                        { blocks =
                          [ C.Block.Mod C.ModType.network
                          , C.Block.Pad 10
                          , C.Block.Mod C.ModType.memory
                          , C.Block.Pad 10
                          , C.Block.Mod C.ModType.processor
                          ]
                        , width = 436
                        }
                    ]
                  , margins = { x = 20, y = 10 }
                  }
              ]
            : List C.Panel
        }
      : C.Layout

let modules =
      C.Modules::{
      , memory = Some
          (   { show_stats = False
              , show_swap = False
              , show_plot = True
              , table_rows = 3
              }
            : C.Memory
          )
      , processor = Some
          (   { core_rows = 0
              , core_padding = 0
              , show_stats = False
              , show_plot = True
              , table_rows = 3
              }
            : C.Processor
          )
      }

in  C.toConfig 1 { x = 1920, y = 1080 } C.Theme::{=} layout modules
