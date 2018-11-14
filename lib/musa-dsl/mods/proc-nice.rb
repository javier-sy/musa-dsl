class Proc
  def _call(value_args, key_value_args)
    if value_args && key_value_args
      call(*value_args, **key_value_args)
    elsif value_args
      call(*value_args)
    elsif key_value_args
      call(**key_value_args)
    else
      call
    end
  end
end
