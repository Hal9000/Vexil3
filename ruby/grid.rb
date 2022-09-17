class Grid
  def initialize
    @hash = {}  # hash as sparse matrix
    rx, ry = RedFlag.where
    self[Red, rx, ry] = RedFlag
    bx, by = BlueFlag.where
    self[Blue, bx, by] = BlueFlag
  end

  def [](team, x, y)
    ax, ay = coordinates(team, x, y)
    @hash[[ax, ay]]
  end

  def []=(team, x, y, obj)
    ax, ay = coordinates(team, x, y)
    return if ax.nil?
    @hash[[ax, ay]] = obj
  end

  def coordinates(team, x, y)
    ax = (team == Red) ? x : GridSize - x + 1 # Absolute coordinates
    ay = (team == Red) ? y : GridSize - y + 1
    [ax, ay]
  end
end
