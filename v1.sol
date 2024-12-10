// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HealthContract {
    // Struct definitions
    struct Patient {
        address patientAddress; // Track patient's address
        string name;
        uint birthDate;
        uint weight;
        uint height;
        string sex;
        uint[] imageIds; // Array to store image identifiers for the patient
    }

    struct Image {
        uint patientId; // Track patient ID for the image
        string beforeImageCID; // Use string for CID
        string afterImageCID; // Use string for CID
        bool isAfterUploaded; // Flag to indicate if after image is uploaded
    }

    struct Practitioner {
        address practitionerAddress; // Track practitioner's address
        string name;
        uint starRating;
        string servicesOffered;
        uint[] patients;
    }

    struct Review {
        address reviewer;
        uint rating;
        string comment;
    }

    // Mappings
    mapping(uint => Patient) private patients;
    mapping(uint => Practitioner) private practitioners;
    mapping(uint => Image) private images;
    mapping(uint => Review[]) private reviewsByPractitioner;

    // Counters for unique IDs
    uint private patientCounter;
    uint private practitionerCounter;
    uint private imageCounter;

    // Events
    event PatientRegistered(uint patientId, string name, uint birthDate, uint weight, uint height, string sex);
    event PractitionerRegistered(uint practitionerId, string name, address practitionerAddress, string servicesOffered);
    event BeforeImageUploaded(uint imageId, uint patientId, string beforeImageCID);
    event AfterImageUploaded(uint imageId, string afterImageCID);
    event ReviewSubmitted(uint patientId, address reviewer, uint rating, string comment);
    // Event to log when a patient is added to a practitioner
    event PatientAddedToPractitioner(uint patientId, uint practitionerId);
    // Modifiers
    modifier onlyPatient(uint patientId) {
        require(msg.sender == patients[patientId].patientAddress, "Not authorized patient");
        _;
    }

    modifier onlyPractitioner(uint practitionerId) {
        require(msg.sender == practitioners[practitionerId].practitionerAddress, "Not authorized practitioner");
        _;
    }

    // Registration functions

    function registerPatient(string memory _name, uint _birthDate, uint _weight, uint _height, string memory _sex) public returns (uint) {
        patientCounter++;
        patients[patientCounter] = Patient({
            patientAddress: msg.sender,
            name: _name,
            birthDate: _birthDate,
            weight: _weight,
            height: _height,
            sex: _sex,
            imageIds: new uint[](0)
        });

        emit PatientRegistered(patientCounter, _name, _birthDate, _weight, _height, _sex);
        return patientCounter;
    }

    function registerPractitioner(string memory _name, address _practitionerAddress, string memory _servicesOffered) public returns (uint) {
        practitionerCounter++;
        practitioners[practitionerCounter] = Practitioner({
            practitionerAddress: _practitionerAddress,
            name: _name,
            starRating: 0,
            servicesOffered: _servicesOffered,
           patients: new uint[](0)
        });

        emit PractitionerRegistered(practitionerCounter, _name, _practitionerAddress, _servicesOffered);
        return practitionerCounter;
    }

    // Image upload functions

    function uploadBeforeImage(uint patientId, string memory beforeImageCID) public onlyPatient(patientId) returns (uint) {
        require(bytes(beforeImageCID).length > 0, "CID cannot be empty");
        imageCounter++;
        images[imageCounter] = Image({
            patientId: patientId,
            beforeImageCID: beforeImageCID,
            afterImageCID: "",
            isAfterUploaded: false
        });
        patients[patientId].imageIds.push(imageCounter);

        emit BeforeImageUploaded(imageCounter, patientId, beforeImageCID);
        return imageCounter;
    }

    function uploadAfterImage(uint imageId, string memory afterImageCID) public onlyPatient(images[imageId].patientId) {
        require(bytes(afterImageCID).length > 0, "CID cannot be empty");
        require(bytes(images[imageId].afterImageCID).length == 0, "After image already uploaded");
        require(!images[imageId].isAfterUploaded, "After image already associated");

        images[imageId].afterImageCID = afterImageCID;
        images[imageId].isAfterUploaded = true;

        emit AfterImageUploaded(imageId, afterImageCID);
    }

    // Review submission function

    function submitReview(uint patientId, uint practitionerId, uint rating, string memory comment) public onlyPractitioner(practitionerId) {
        require(rating >= 0 && rating <= 5, "Rating should be between 0 and 5");

        // Get the current reviews for the practitioner
        Review[] storage reviews = reviewsByPractitioner[practitionerId];

        // Calculate the new star rating
        uint currentTotalRating = practitioners[practitionerId].starRating * reviews.length;
        uint newTotalRating = currentTotalRating + rating;
        uint newStarRating = reviews.length == 0 ? rating : newTotalRating / (reviews.length + 1);

        // Update the star rating for the practitioner
        practitioners[practitionerId].starRating = newStarRating;

        // Add the new review
        reviewsByPractitioner[practitionerId].push(Review({
            reviewer: msg.sender,
            rating: rating,
            comment: comment
        }));

        emit ReviewSubmitted(patientId, msg.sender, rating, comment);
    }

    // Utility functions for retrieval

    // Get a specific patient
    function getPatient(uint patientId) public view returns (address, string memory, uint, uint, uint, string memory, uint[] memory) {
        Patient memory patient = patients[patientId];
        return (patient.patientAddress, patient.name, patient.birthDate, patient.weight, patient.height, patient.sex, patient.imageIds);
    }

    // Get a specific practitioner
    function getPractitioner(uint practitionerId) public view returns (address, string memory, uint, string memory, uint[] memory) {
        Practitioner memory practitioner = practitioners[practitionerId];
        return (practitioner.practitionerAddress, practitioner.name, practitioner.starRating, practitioner.servicesOffered, practitioner.patients);
    }

    // Get a specific image
    function getImage(uint imageId) public view returns (uint, string memory, string memory, bool) {
        Image memory image = images[imageId];
        return (image.patientId, image.beforeImageCID, image.afterImageCID, image.isAfterUploaded);
    }

    // Get all patients
    function getAllPatients() public view returns (uint[] memory) {
        uint[] memory patientIds = new uint[](patientCounter);
        for (uint i = 1; i <= patientCounter; i++) {
            patientIds[i - 1] = i;
        }
        return patientIds;
    }

    // Get all practitioners
    function getAllPractitioners() public view returns (uint[] memory) {
        uint[] memory practitionerIds = new uint[](practitionerCounter);
        for (uint i = 1; i <= practitionerCounter; i++) {
            practitionerIds[i - 1] = i;
        }
        return practitionerIds;
    }

    // Get all images
    function getAllImages() public view returns (uint[] memory) {
        uint[] memory imageIds = new uint[](imageCounter);
        for (uint i = 1; i <= imageCounter; i++) {
            imageIds[i - 1] = i;
        }
        return imageIds;
    }

    function getReviews(uint practitionerId) public view returns (address[] memory, uint[] memory, string[] memory) {
        Review[] storage reviews = reviewsByPractitioner[practitionerId];
        address[] memory reviewers = new address[](reviews.length);
        uint[] memory ratings = new uint[](reviews.length);
        string[] memory comments = new string[](reviews.length);

        for (uint i = 0; i < reviews.length; i++) {
            reviewers[i] = reviews[i].reviewer;
            ratings[i] = reviews[i].rating;
            comments[i] = reviews[i].comment;
        }

        return (reviewers, ratings, comments);
    }

    // Method to get a patient by address
    function getPatientByAddress(address _patientAddress) public view returns (uint, string memory, uint, uint, uint, string memory, uint[] memory) {
        for (uint i = 1; i <= patientCounter; i++) {
            if (patients[i].patientAddress == _patientAddress) {
                Patient memory patient = patients[i];
                return (i, patient.name, patient.birthDate, patient.weight, patient.height, patient.sex, patient.imageIds);
            }
        }
        revert("Patient not found");
    }

    // Method to get a practitioner by address
    function getPractitionerByAddress(address _practitionerAddress) public view returns (uint, string memory, uint, string memory, uint[] memory) {
        for (uint i = 1; i <= practitionerCounter; i++) {
            if (practitioners[i].practitionerAddress == _practitionerAddress) {
                Practitioner memory practitioner = practitioners[i];
                return (i, practitioner.name, practitioner.starRating, practitioner.servicesOffered, practitioner.patients);
            }
        }
        revert("Practitioner not found");
    }
    // Method for a patient to send money to a practitioner
    function sendMoneyToPractitioner(uint patientId, uint practitionerId) public payable onlyPatient(patientId) {
        require(practitioners[practitionerId].practitionerAddress != address(0), "Practitioner not found");

        // Add the patient to the practitioner's list of patients
        practitioners[practitionerId].patients.push(patientId);

        // Optionally, you can transfer the sent amount to the practitioner
        payable(practitioners[practitionerId].practitionerAddress).transfer(msg.value);

        emit PatientAddedToPractitioner(patientId, practitionerId);
    }
}