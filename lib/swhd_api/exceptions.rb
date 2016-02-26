module SwhdApi
  class MissingCredentials < ArgumentError; end
  class MissingUrl < ArgumentError; end
  class NoSession < StandardError; end
  class MissingResource < ArgumentError; end
  class TimedOut < StandardError; end
  class PartialFile < StandardError; end
  class NoResponse < StandardError; end
  class RequestFailed < StandardError; end
end