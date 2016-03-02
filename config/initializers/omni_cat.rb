OmniCat.configure do |config|
  config.token_patterns = {
    minus: [/[\s\t\n\r]+/, /(@[\w\d]+)/],
    plus: [/[\p{L}\-0-9]{2,}/, /[\!\?]/, /[\:\)\(\;\-\|]{2,3}/, /\p{Han}/]
  }
end
