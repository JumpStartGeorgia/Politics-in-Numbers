class String
  def soft_titleize
    self.gsub(/\b(?<!['â`])[[:alpha:]]/) { |match| match.mb_chars.capitalize.to_s }
  end
end
