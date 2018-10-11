class Object
  def send_nice(method_name, *args, **key_args, &block)
    _send_nice method_name, args, key_args, &block
  end

  def _send_nice(method_name, args, key_args, &block)
    if args && !args.empty?
      if key_args && !key_args.empty?
        send method_name, *args, **key_args, &block
      else
        send method_name, *args, &block
      end
    else
      if key_args && !key_args.empty?
        send method_name, **key_args, &block
      else
        send method_name, &block
      end
    end
  end
end
