module Helper
  def self.sanitize (filename)
    # Bad as defined by wikipedia: https://en.wikipedia.org/wiki/Filename#Reserved_characters_and_words
    # Also have to escape the backslash
    bad_chars = [ '/', '\\', '?', '%', '*', ':', '|', '"', '<', '>', '.', ' ' ]
    bad_chars.each do |bad_char|
      filename.gsub!(bad_char, '_')
    end
    filename
  end
end
