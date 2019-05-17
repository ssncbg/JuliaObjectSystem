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
    spr = super
    for class in super
        append!(slt, class.slots)
        append!(spr, class.super)
    end
    append!(slt, slots)
    #append!(spr, super)

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
#=
@defgeneric foo(c)
@macroexpand@defmethod foo(c::C2) = "I do experiments and research at $(c.b)! But not in rats!"
@defmethod foo(c::C2) = "I do experiments and research at $(c.b)! But not in rats!"
=#
function is_super_class(class::Class, name)
    for c in class.super
        if c.name === name
            return true
        end
    end

    return false
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

    i = 1
    methods = f.methods

    for parameter in parameters
        matchmethods = []
        for m in methods
            if parameter === m.parameters[i]
                push!(matchmethods, m)
            elseif is_super_class(classes[i], m.parameters[i])
                push!(matchmethods, m)
            end
        end

        if length(matchmethods) == 0
            return error("No applicable method")
        end

        methods = matchmethods
        i += 1
    end

    return methods[1].native_function(instances...)
end
#=
C1 = make_class(:C1, [], [:a])
C2 = make_class(:C2, [], [:b, :c])
C3 = make_class(:C3, [C1, C2], [:d])

@defclass(C1, [], a)
@defclass(C2, [], b, c)
@defclass(C3, [C1, C2], d)

c3i1 = make_instance(C3, :a=>1, :b=>2, :c=>3, :d=>4)
c3i2 = make_instance(C3, :b=>2)

get_slot(c3i2, :b)
set_slot!(c3i2, :b, 3)
println([get_slot(c3i1, s) for s in [:a, :b, :c]])
#=
c3i1.a
c3i1.e
c3i2.a
c3i2.a = 5
c3i2.a
=#
@defgeneric foo(c)
@defmethod foo(c::C1) = 1
@defmethod foo(c::C2) = c.b
@defgeneric bar(c,d)
@defmethod bar(c::C2, d::C3) = c.b + d.b

foo(make_instance(C1))
foo(make_instance(C2, :b=>42))
bar(make_instance(C2, :b=>42), make_instance(C3, :b=>42))
bar(c3i1, c3i2)
=#
