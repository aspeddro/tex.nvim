-- Default options
return {
  engine = 'latexmk',
  compile = {
    events = { 'BufWritePost' },
    watchlist = true
  },
  viewer = nil,
  engines = {
    tectonic = {},
    latexmk = {
      args = {
        '-pdf', -- generate pdf
        ['-interaction'] = 'nonstopmode'
      }
    },
    pdflatex = {
      args = {
        ['-interaction'] = 'nonstopmode'
      }
    },
    xelatex = {
      args = {
        ['-interaction'] = 'nonstopmode'
      }
    },
    lualatex = {
      args = {
        ['-interaction'] = 'nonstopmode'
      }
    }
  }
}
