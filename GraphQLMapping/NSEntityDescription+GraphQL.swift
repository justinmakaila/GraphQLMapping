import CoreData
import GraphQL
import RemoteMapping


/// Mapping for GraphQL Relationships
protocol GraphQLRelationshipMapping {
    var graphQLRelayConnection: Bool { get }
}

public protocol GraphQLEntity {
    /// The field name representing the entity
    var fieldName: String { get }
    /// The collection name representing a collection of entities
    var collectionName: String { get }
}

private enum MappingKey: String {
    case RelayConnection = "GraphQL.RelayConnection"
    case FieldName = "GraphQL.FieldName"
    case CollectionName = "GraphQL.CollectionName"
}

extension NSPropertyDescription {
    public var graphQLPropertyName: String {
        return userInfo?[MappingKey.FieldName.rawValue] as? String ?? remotePropertyName
    }
}

extension NSRelationshipDescription: GraphQLRelationshipMapping {
    public var graphQLRelayConnection: Bool {
        return userInfo?[MappingKey.RelayConnection.rawValue] != nil
    }
}

extension NSEntityDescription: GraphQLEntity {
    public var fieldName: String {
        return (userInfo?[MappingKey.FieldName.rawValue] as? String ?? name ?? managedObjectClassName).lowercaseString
    }
    
    public var collectionName: String {
        return userInfo?[MappingKey.CollectionName.rawValue] as? String ?? "\(fieldName)s"
    }
}

public extension NSEntityDescription {
    /// Returns a selection set representing the entity.
    func selectionSet(parent: NSEntityDescription? = nil, relationshipType: RelationshipType = .Array, excludeKeys: Set<String> = []) -> GraphQL.SelectionSet {
        return remoteProperties
            .filter { propertyDescription in
                return !excludeKeys.contains(propertyDescription.graphQLPropertyName)
            }
            .flatMap { propertyDescription -> GraphQL.Field? in
                let remoteKey = propertyDescription.graphQLPropertyName
                
                if propertyDescription is NSAttributeDescription {
                    return GraphQL.Field(name: remoteKey)
                } else if let relationshipDescription = propertyDescription as? NSRelationshipDescription where (relationshipType != .None) {
                    guard let destinationEntity = relationshipDescription.destinationEntity
                    else {
                        return nil
                    }
                    
                    let isValidRelationship = !(parent != nil && (parent == destinationEntity) && !relationshipDescription.toMany)
                    
                    if isValidRelationship {
                        if relationshipDescription.toMany {
                            return fieldForToManyRelationship(destinationEntity, relationshipName: remoteKey, relationshipType: relationshipType, parent: self, relayConnection: relationshipDescription.graphQLRelayConnection)
                        } else {
                            return fieldForToOneRelationship(destinationEntity, relationshipName: remoteKey, relationshipType: relationshipType, parent: self)
                        }
                    }
                }
                
                return nil
        }
    }
    
    /// Returns a field representing a to-one relationship
    private func fieldForToOneRelationship(entity: NSEntityDescription, relationshipName: String, relationshipType: RelationshipType, parent: NSEntityDescription?) -> GraphQL.Field {
        return GraphQL.Field(name: relationshipName, selectionSet: entity.selectionSet(parent, relationshipType: relationshipType))
    }
    
    /// Returns a field representing a to-many relationship
    private func fieldForToManyRelationship(entity: NSEntityDescription, relationshipName: String, relationshipType: RelationshipType, parent: NSEntityDescription?, relayConnection: Bool = false) -> GraphQL.Field? {
        if relayConnection {
            return GraphQL.Field(name: relationshipName, selectionSet: [
                    GraphQL.Field(name: "edges", selectionSet: [
                        GraphQL.Field(name: "node", selectionSet: entity.selectionSet(parent, relationshipType: relationshipType))
                    ])
                ]
            )
        } else {
            return GraphQL.Field(name: relationshipName, selectionSet: entity.selectionSet(parent, relationshipType: relationshipType))
        }
    }
}