class AuthError < CustomError
  def initialize(message = "Not Authorized to access #{Current.path}")
    super(message, status: 403, code: :forbidden)
  end

  def to_s
    "#{code} #{message}"
  end
end
