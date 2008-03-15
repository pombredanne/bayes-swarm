# Provides common functionalities reused across scripts
module Common
  
  # Given an array of command-line parameters returns the part of them
  # which is before or after the +opt+ parameter, which acts as separator
  def split_params(params,opt, after)
    reject = after
    res = params.collect do |p|
      reject = !reject if p == opt
      p if !reject && p != opt
    end
    return res.compact
  end

end