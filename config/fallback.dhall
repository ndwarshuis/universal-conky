let C = ./config.dhall

let memory =
      C.ModType.memory
        { show_stats = False
        , show_swap = False
        , show_plot = True
        , table_rows = 3
        }

let processor =
      C.ModType.processor
        { core_rows = 0
        , core_padding = 0
        , show_stats = False
        , show_plot = True
        , table_rows = 3
        }

let layout =
      { anchor = { x = 12, y = 11 }
      , panels =
        [ C.Panel.PPanel
            { columns =
              [ C.Column.CCol
                  { blocks =
                    [ C.mod C.ModType.network
                    , C.Block.Pad 10
                    , C.mod memory
                    , C.Block.Pad 10
                    , C.mod processor
                    ]
                  , width = 436
                  }
              ]
            , margins = { x = 20, y = 10 }
            }
        ]
      }

in  C.toConfig 1 1920 1080 C.Theme::{=} layout
