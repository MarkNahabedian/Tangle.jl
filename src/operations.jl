export Operation, next_op_sequence_number


"""
    abstract type Operation

Operation is the abstract supertype for all Operations.  Operations
provide us with a way to record the history of a loop.
"""
abstract type Operation
# Every Operation should have a field named "sequence" that is
# unique within a given Loop.
# Should every operation (except for InitializeLoop) have a previous Loop?
end

"""
    next_op_sequence_number()

next_op_sequence_number is used to assign a monotonically increasing
sequence number to each new operation.
"""
next_op_sequence_number = 
    let
        # Should we use next_operation_sequence_number instead?
    seq::Int = 1

    function ()
        nxt = seq
        seq += 1
        return nxt
    end
end


