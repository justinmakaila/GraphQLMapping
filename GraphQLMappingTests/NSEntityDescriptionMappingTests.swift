import XCTest
import CoreData
import GraphQL

@testable
import GraphQLMapping


class NSEntityDescriptionMappingTests: GraphQLMappingTestCase {
    func test_NSEntityDescriptionGraphQL_ProvidesSelectionSet() {
        let userEntity = entityForName("User")
        let userSelectionSet: GraphQL.SelectionSet = [
            "age",
            "name",
            GraphQL.Field(name: "pets", selectionSet: [
                GraphQL.Field(name: "edges", selectionSet: [
                    GraphQL.Field(name: "node", selectionSet: [
                        "name"
                    ])
                ])
            ])
        ]
        
        XCTAssertTrue(userEntity.selectionSet() == userSelectionSet)
        
        let dogEntity = entityForName("Dog")
        let dogSelectionSet: GraphQL.SelectionSet = [
            "name",
            GraphQL.Field(name: "owner", selectionSet: [
                "name",
                "age",
                GraphQL.Field(name: "pets", selectionSet: [
                    GraphQL.Field(name: "edges", selectionSet: [
                        GraphQL.Field(name: "node", selectionSet: [
                            "name"
                        ])
                    ])
                ])
            ])
        ]
        
        XCTAssertTrue(dogEntity.selectionSet() == dogSelectionSet)
        
        let catEntity = entityForName("Cat")
        let catSelectionSet: GraphQL.SelectionSet = [
            "name",
            GraphQL.Field(name: "owner", selectionSet: [
                "name",
                "age",
                GraphQL.Field(name: "pets", selectionSet: [
                    GraphQL.Field(name: "edges", selectionSet: [
                        GraphQL.Field(name: "node", selectionSet: [
                            "name"
                        ])
                    ])
                ])
            ])
        ]
        
        XCTAssertTrue(catEntity.selectionSet() == catSelectionSet)
    }
    
    func test_NSEntityDescriptionGraphQL_ProvidesDefaultFieldName() {
        let dogEntity = entityForName("Dog")
        
        XCTAssertTrue(dogEntity.fieldName == "dog")
    }
    
    func test_NSEntityDescriptionGraphQL_ProvidesFieldName() {
        let userEntity = entityForName("User")
        
        XCTAssertTrue(userEntity.fieldName == "user")
    }
    
    func test_NSEntityDescriptionGraphQL_ProvidesDefaultCollectionName() {
        let dogEntity = entityForName("Dog")
        
        XCTAssertTrue(dogEntity.collectionName == "dogs")
    }
    
    func test_NSEntityDescriptionGraphQL_ProvidesCollectionName() {
        let userEntity = entityForName("User")
        
        XCTAssertTrue(userEntity.collectionName == "users")
    }
}
