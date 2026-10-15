object DIFFMainForm: TDIFFMainForm
  Left = 0
  Top = 0
  Caption = 'Delphi IDE Fix Favorites'
  ClientHeight = 1484
  ClientWidth = 1117
  Color = clBtnFace
  Constraints.MinHeight = 500
  Constraints.MinWidth = 600
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  TextHeight = 15
  object SplitterGrids: TSplitter
    Left = 0
    Top = 421
    Width = 1117
    Height = 5
    Cursor = crVSplit
    Align = alTop
  end
  object PanelSortPaths: TPanel
    Left = 0
    Top = 0
    Width = 1117
    Height = 121
    Align = alTop
    BevelOuter = bvNone
    Padding.Left = 6
    Padding.Top = 6
    Padding.Right = 6
    TabOrder = 0
    object LabelSortPaths: TLabel
      Left = 6
      Top = 6
      Width = 1105
      Height = 15
      Align = alTop
      Caption = 'Sort paths'
      FocusControl = MemoSortPaths
    end
    object MemoSortPaths: TMemo
      AlignWithMargins = True
      Left = 6
      Top = 24
      Width = 1105
      Height = 97
      Margins.Left = 0
      Margins.Right = 0
      Margins.Bottom = 0
      Align = alClient
      ScrollBars = ssBoth
      TabOrder = 0
      WordWrap = False
    end
  end
  object GroupBoxFavorites: TGroupBox
    AlignWithMargins = True
    Left = 6
    Top = 127
    Width = 1105
    Height = 294
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 0
    Align = alTop
    Caption = 'Favorite Projects'
    TabOrder = 1
    object StringGridFavorites: TStringGrid
      Left = 2
      Top = 17
      Width = 1101
      Height = 240
      Align = alClient
      ColCount = 2
      DefaultRowHeight = 22
      FixedCols = 0
      RowCount = 2
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing, goRowSelect, goThumbTracking]
      TabOrder = 0
      OnDrawCell = StringGridDrawCell
      ColWidths = (
        70
        990)
    end
    object PanelFavoritesButtons: TPanel
      Left = 2
      Top = 257
      Width = 1101
      Height = 35
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 1
      object ButtonFavoritesRemoveMissing: TButton
        Left = 4
        Top = 5
        Width = 130
        Height = 25
        Caption = 'Remove missing'
        TabOrder = 0
        OnClick = ButtonFavoritesRemoveMissingClick
      end
      object ButtonFavoritesSort: TButton
        Left = 140
        Top = 5
        Width = 90
        Height = 25
        Caption = 'Sort'
        TabOrder = 1
        OnClick = ButtonFavoritesSortClick
      end
    end
  end
  object GroupBoxClosed: TGroupBox
    AlignWithMargins = True
    Left = 6
    Top = 426
    Width = 1105
    Height = 1017
    Margins.Left = 6
    Margins.Top = 0
    Margins.Right = 6
    Margins.Bottom = 0
    Align = alClient
    Caption = 'Closed Projects'
    TabOrder = 2
    object StringGridClosed: TStringGrid
      Left = 2
      Top = 17
      Width = 1101
      Height = 963
      Align = alClient
      ColCount = 2
      DefaultRowHeight = 22
      FixedCols = 0
      RowCount = 2
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing, goRowSelect, goThumbTracking]
      TabOrder = 0
      OnDrawCell = StringGridDrawCell
      ColWidths = (
        70
        990)
    end
    object PanelClosedButtons: TPanel
      Left = 2
      Top = 980
      Width = 1101
      Height = 35
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 1
      object ButtonClosedRemoveMissing: TButton
        Left = 4
        Top = 5
        Width = 130
        Height = 25
        Caption = 'Remove missing'
        TabOrder = 0
        OnClick = ButtonClosedRemoveMissingClick
      end
      object ButtonClosedSort: TButton
        Left = 140
        Top = 5
        Width = 90
        Height = 25
        Caption = 'Sort'
        TabOrder = 1
        OnClick = ButtonClosedSortClick
      end
    end
  end
  object PanelBottom: TPanel
    Left = 0
    Top = 1443
    Width = 1117
    Height = 41
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    object ButtonReload: TButton
      Left = 10
      Top = 8
      Width = 130
      Height = 25
      Caption = 'Reload from registry'
      TabOrder = 0
      OnClick = ButtonReloadClick
    end
    object ButtonWriteRegistry: TButton
      Left = 146
      Top = 8
      Width = 130
      Height = 25
      Caption = 'Write to registry'
      TabOrder = 1
      OnClick = ButtonWriteRegistryClick
    end
  end
end
