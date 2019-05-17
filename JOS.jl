struct Class
    name
    super
    slots
end

struct Instance
    class
    slots_values
end

function make_class(name, super, slots)
    slt = []
    spr = []
    for class in super
        append!(slt, class.slots)
        push!(spr, class)
        append!(spr, class.super)
    end
    append!(slt, slots)

    Class(name, tuple(spr...), tuple(slt...))
end

macro defclass(name, super, slots...)
    :($(esc(name)) = make_class($(QuoteNode(name)), $super, $slots))
end

function make_instance(class, values...)
    values = Dict(values)
    slots_values = Dict{Any, Any}(zip(class.slots, fill(nothing, length(class.slots))))
    for (slot, value) in values
        if haskey(slots_values, slot)
            slots_values[slot] = value
        else
            error("Slot $(slot) is missing")
        end
    end

    Instance(class, slots_values)
end

function get_slot(instance, slot)
    slots_values = getfield(instance, :slots_values)
    if haskey(slots_values, slot)
        value = slots_values[slot]
        value === nothing ? error("Slot $(slot) is unbound") : value
    else
        error("Slot $(slot) is missing")
    end
end

function set_slot!(instance, slot, value)
    slots_values = getfield(instance, :slots_values)
    if haskey(slots_values, slot)
        slots_values[slot] = value
    else
        error("Slot $slot is missing")
    end
end

function Base.getproperty(instance::Instance, slot::Symbol)
    get_slot(instance, slot)
end

function Base.setproperty!(instance::Instance, slot::Symbol, value)
    set_slot!(instance, slot, value)
end

struct Generic
    name
    parameters
    methods
end

struct Method
    name
    parameters
    native_function
end

function make_generic(name, parameters)
    Generic(name, parameters, [])
end

macro defgeneric(expr)
    name = expr.args[1]
    parameters = tuple(expr.args[2:end]...)
    :($(esc(name)) = make_generic($(QuoteNode(name)), $(parameters)))
end

function make_method(name, parameters, native_function)
    Method(name, parameters, native_function)
end

macro defmethod(expr)
    name = expr.args[1].args[1]
    body = expr.args[2].args[2]

    types = []
    parameters = []
    native_function = "("

    variables = expr.args[1].args[2:end]
    for var in variables
        #push!(parameters, var.args[1])
        native_function = string(native_function, var.args[1] , ",")
        push!(types, var.args[2])
    end

    native_function = string(native_function, ")")
    native_function = Meta.parse(native_function)

    types = tuple(types...)

    :(push!($(esc(name)).methods, make_method($(QuoteNode(name)), $types, $(esc(native_function)) -> $(esc(body)))))
end

function effectiveMethod(inputParameters, inputClasses,  inputMethods)
    methods = inputMethods

    i = 1
    for parameter in inputParameters
        matchmethods = []

        for m in methods
            if parameter === m.parameters[i]
                push!(matchmethods, m)
            end
        end

        classes = inputClasses[i].super
        for  class in classes
            for m in methods
                if class.name === m.parameters[i]
                    push!(matchmethods, m)
                end
            end
        end

        if length(matchmethods) == 0
            return error("No applicable method")
        end

        methods = matchmethods
        i += 1
    end

    return methods
end

(f::Generic)(args...) = begin
    parameters = []
    instances = []
    classes = []
    for instance in args
        class = getfield(instance, :class)
        name = class.name
        push!(classes, class)
        push!(parameters, name)
        push!(instances, instance)
    end
    parameters = tuple(parameters...)

    return effectiveMethod(parameters, classes, f.methods)[1].native_function(instances...)
end
