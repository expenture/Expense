class String
  def sql_format(format)
    format = format.to_sym unless format.is_a?(Symbol)
    if format == :postgresql
      self.tr('`', '"')
    else
      self
    end
  end
end
