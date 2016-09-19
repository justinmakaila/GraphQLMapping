import XCTest
import CoreData
import GraphQL

@testable
import GraphQLMapping


class NSEntityDescriptionMappingTests: GraphQLMappingTestCase {
    func test_NSEntityDescriptionGraphQL_ProvidesSelectionSet() {
        let userEntity = entityForName("User")
        let userSelectionSet: GraphQL.SelectionSet = [
            "address",
            "age",
            GraphQL.Field(name: "customAddress", selectionSet: [
                "street",
                "street2",
                "city",
                "state",
                "postalCode",
                "country"
            ]),
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
                "address",
                "age",
                GraphQL.Field(name: "customAddress", selectionSet: [
                    "street",
                    "street2",
                    "city",
                    "state",
                    "postalCode",
                    "country"
                ]),
                "name",
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
                "address",
                "age",
                GraphQL.Field(name: "customAddress", selectionSet: [
                    "street",
                    "street2",
                    "city",
                    "state",
                    "postalCode",
                    "country"
                ]),
                "name",
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
    
    func test_NSEntityDescriptionGraphQL_ProvidesSelectionSetExcludingKeys() {
        let userEntity = entityForName("User")
        
        let userSelectionSet: GraphQL.SelectionSet = [
            "age",
            "name"
        ]
        
        XCTAssertTrue(userEntity.selectionSet(excludeKeys: ["pets", "address", "customAddress"]) == userSelectionSet)
    }
    
    func test_NSEntityDescriptionGraphQL_ProvidesDefaultFieldName() {
        let dogEntity = entityForName("Dog")
        
        XCTAssertTrue(dogEntity.fieldName.lowercased() == "dog")
    }
    
    func test_NSEntityDescriptionGraphQL_ProvidesFieldName() {
        let userEntity = entityForName("User")
        
        XCTAssertTrue(userEntity.fieldName == "user")
    }
    
    func test_NSEntityDescriptionGraphQL_ProvidesDefaultCollectionName() {
        let dogEntity = entityForName("Dog")
        
        XCTAssertTrue(dogEntity.collectionName.lowercased() == "dogs")
    }
    
    func test_NSEntityDescriptionGraphQL_ProvidesCollectionName() {
        let userEntity = entityForName("User")
        
        XCTAssertTrue(userEntity.collectionName == "users")
    }
    
    func test_NSEntityDescriptionGraphQL_ProvidesCustomFieldMapping() {
        let userEntity = entityForName("User")
        
        let defaultSelectionSet = userEntity.selectionSet()
        let addressField = defaultSelectionSet.filter { $0.name == "address" }.first!
        XCTAssertTrue(addressField.selectionSet.isEmpty)
        
        let customField = GraphQL.Field(name: "address", selectionSet: [
            "street",
            "street2",
            "city",
            "state",
            "postalCode",
            "country"
        ])
        
        let customSelectionSet = userEntity.selectionSet(customFields: [
            "address": customField
        ])
        
        let customAddressField = customSelectionSet.filter { $0.name == "address" } .first!
        XCTAssertTrue(customAddressField == customField)
    }
    
    func test_NSENtityDescriptionGraphQL_ProvidesCustomFieldMappingInDataModel() {
        let userEntity = entityForName("User")
        let defaultSelectionSet = userEntity.selectionSet()
        let addressField = defaultSelectionSet.filter { $0.name == "customAddress" }.first!
        
        let customField = GraphQL.Field(name: "customAddress", selectionSet: [
            "street",
            "street2",
            "city",
            "state",
            "postalCode",
            "country"
        ])
        
        XCTAssertTrue(addressField == customField)
    }
}
