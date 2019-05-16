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
    s = append!([], slots)
    for class in super
        append!(s, class.slots)
    end

    Class(name, super, tuple(s...))
end

C1 = make_class(:C1, [], [:a])
C2 = make_class(:C2, [], [:b, :c])
C3 = make_class(:C3, [C1, C2], [:d])

macro defclass(name, super, slots...)
    :($(esc(name)) = make_class($(QuoteNode(name)), $super, $slots))
end

@defclass(C1, [], a)
@defclass(C2, [], b, c)
@defclass(C3, [C1, C2], d)

function make_instance(class, values...)
    values = Dict(values)
    slots_values = Dict{Any, Any}(zip(class.slots, fill(nothing, length(class.slots))))
    for (slot, value) in values
        if haskey(slots_values, slot)
            slots_values[slot] = value
        else
            error("ERROR: Slot $(slot) is missing")
        end
    end

    Instance(class, slots_values)
end

c3i1 = make_instance(C3, :a=>1, :b=>2, :c=>3, :d=>4)
c3i2 = make_instance(C3, :b=>2)

function get_slot(instance, slot)
    slots_values = getfield(instance, :slots_values)
    if haskey(slots_values, slot)
        value = slots_values[slot]
        value === nothing ? error("ERROR: Slot $(slot) is unbound") : value
    else
        error("ERROR: Slot $(slot) is missing")
    end
end

function set_slot!(instance, slot, value)
    slots_values = getfield(instance, :slots_values)
    if haskey(slots_values, slot)
        slots_values[slot] = value
    else
        error("ERROR: Slot $slot is missing")
    end
end

get_slot(c3i2, :b)
set_slot!(c3i2, :b, 3)
println([get_slot(c3i1, s) for s in [:a, :b, :c]])

function Base.getproperty(instance::Instance, slot::Symbol)
    get_slot(instance, slot)
end

function Base.setproperty!(instance::Instance, slot::Symbol, value)
    set_slot!(instance, slot, value)
end

c3i1.a
c3i1.e
c3i2.a
c3i2.a = 5
c3i2.a

#############
# Functions #
#############

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

function make_method(name, parameters, body)
    native_function = parameters -> body
    Method(name, parameters, native_function)
end

macro defmethod(expr)
    name = expr.args[1].args[1]
    parameters = ()
    parameters_temp = expr.args[1].args[2:end]
    for p in parameters_temp
        parameter = tuple(p.args[1:end]...)
        push!(parameters, parameter)
    end
    body = expr.args[2].args[2]
    :($(esc(name)) = make_method($(QuoteNode(name)), $(types), $(parameters) -> $(esc(body))))
end

@defgeneric foo(c)
@defmethod foo(c::C1) = 1
@macroexpand @defmethod foo(c::C2) = c.b

#foo(make_instance(C1))
#foo(make_instance(C2, :b=>42))
