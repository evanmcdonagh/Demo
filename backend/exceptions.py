"""Custom exception classes for domain errors."""


class DomainException(Exception):
    """Base exception for domain errors."""
    pass


class ResourceNotFoundError(DomainException):
    """Raised when a resource is not found."""
    pass


class ResourceAlreadyExistsError(DomainException):
    """Raised when attempting to create a duplicate resource."""
    pass


class CapacityExceededError(DomainException):
    """Raised when event capacity is exceeded."""
    pass


class RepositoryError(DomainException):
    """Raised when database operations fail."""
    pass
