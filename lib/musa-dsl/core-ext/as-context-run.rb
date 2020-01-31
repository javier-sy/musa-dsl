module AsContextRun
  def as_context_run(procedure, *list_or_key_args, **key_args)
    _as_context_run procedure, list_or_key_args, key_args
  end

  def _as_context_run(procedure, list_or_key_args = nil, key_args = nil)
    if !list_or_key_args.nil? && list_or_key_args.is_a?(Hash)
      key_args = list_or_key_args
      list_or_key_args = nil
    end

    if procedure.lambda?
      if !list_or_key_args.nil? && !list_or_key_args.empty?
        if !key_args.nil? && !key_args.empty?
          procedure.call *list_or_key_args, **key_args
        else
          procedure.call *list_or_key_args
        end
      else
        if !key_args.nil? && !key_args.empty?
          procedure.call **key_args
        else
          procedure.call
        end
      end
    else
      if !list_or_key_args.nil? && !list_or_key_args.empty?
        if !key_args.nil? && !key_args.empty?
          instance_exec *list_or_key_args, **key_args, &procedure
        else
          instance_exec *list_or_key_args, &procedure
        end
      else
        if !key_args.nil? && !key_args.empty?
          instance_exec **key_args, &procedure
        else
          instance_eval &procedure
        end
      end
    end
  end

  def with(*list_args, **key_args, &block)
    _as_context_run(block, list_args, key_args)
  end

  def _with(list_args = nil, key_args = nil, &block)
    _as_context_run(block, list_args, key_args)
  end
end
